import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/constants/sdk_constants.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/loggers/logger_adapter.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/sdk/sdk_error_handler.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/service/message/message_service.dart';
// ignore: implementation_imports
import 'package:meeting_place_core/src/utils/cached_did_resolver.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../fixtures/sdk.dart';
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage/in_memory_storage.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['test/.env']);

Future<DatabaseApi> _openMatrixDatabase(MatrixDatabaseContext context) async {
  sqfliteFfiInit();
  final directory = Directory(
    '${Directory.systemTemp.path}/meeting_place_core_test_matrix',
  );
  await directory.create(recursive: true);
  return MatrixSdkDatabase.init(
    context.databaseName,
    database: await databaseFactoryFfi.openDatabase(
      '${directory.path}/${context.databaseName}.sqlite',
    ),
  );
}

MatrixConfig getMatrixConfig() => MatrixConfig(
  mediatorDid: getMediatorDid(),
  controlPlaneDid: getControlPlaneDid(),
  homeserver: getMatrixHomeserver(),
  databaseFactory: const CallbackMatrixDatabaseFactory(
    openDatabase: _openMatrixDatabase,
  ),
);

Future<MeetingPlaceCoreSDK> initSDKInstance({
  Wallet? wallet,
  String? deviceToken,
  bool withoutDevice = false,
  ChannelRepository? channelRepository,
}) async {
  final (sdk, _) = await _initSdkAndOptionalDidcomm(
    wallet: wallet,
    deviceToken: deviceToken,
    withoutDevice: withoutDevice,
    channelRepository: channelRepository,
    buildDidcomm: false,
  );
  return sdk;
}

/// Test-only helper that returns the SDK alongside a [DIDCommTransport] wired
/// to the same wallet, key repository, and channel repository. Used by
/// mediator integration tests that exercise low-level transport semantics
/// (subscription wrapper, keepMessage, deleteMessageDelay) which the public
/// [MeetingPlaceCoreSDK.subscribe] surface intentionally does not expose.
Future<(MeetingPlaceCoreSDK, DIDCommTransport)> initSDKWithDidcomm({
  Wallet? wallet,
  String? deviceToken,
  bool withoutDevice = false,
  ChannelRepository? channelRepository,
}) async {
  final (sdk, didcomm) = await _initSdkAndOptionalDidcomm(
    wallet: wallet,
    deviceToken: deviceToken,
    withoutDevice: withoutDevice,
    channelRepository: channelRepository,
    buildDidcomm: true,
  );
  return (sdk, didcomm!);
}

Future<(MeetingPlaceCoreSDK, DIDCommTransport?)> _initSdkAndOptionalDidcomm({
  required Wallet? wallet,
  required String? deviceToken,
  required bool withoutDevice,
  required ChannelRepository? channelRepository,
  required bool buildDidcomm,
}) async {
  await ensureVodozemacInitialized();
  final effectiveWallet = wallet ?? PersistentWallet(InMemoryKeyStore());
  final storage = InMemoryStorage();
  final keyRepository = KeyRepositoryImpl(storage: storage);
  final effectiveChannelRepository =
      channelRepository ?? ChannelRepositoryImpl(storage: storage);
  final config = getMatrixConfig();

  final sdk = await MeetingPlaceCoreSDK.create(
    wallet: effectiveWallet,
    repositoryConfig: RepositoryConfig(
      connectionOfferRepository: ConnectionOfferRepositoryImpl(
        storage: storage,
      ),
      groupRepository: GroupRepositoryImpl(storage: storage),
      keyRepository: keyRepository,
      channelRepository: effectiveChannelRepository,
    ),
    config: config,
  );

  if (!withoutDevice) {
    await sdk.registerForPushNotifications(
      deviceToken ?? SDKFixture.generateRandomDeviceToken(),
    );
  }

  if (!buildDidcomm) {
    return (sdk, null);
  }

  // Build a sibling DIDCommTransport that shares the SDK's wallet + key
  // repository so DIDs minted via [sdk.generateDid] resolve through it. The
  // wiring mirrors [MeetingPlaceCoreSDK.create]; keep them in sync if the
  // production assembly changes.
  const options = MeetingPlaceCoreSDKOptions();
  final logger = LoggerAdapter(
    className: 'MediatorIntegrationTest',
    sdkName: coreSDKName,
    logger: DefaultMeetingPlaceCoreSDKLogger(
      className: 'MediatorIntegrationTest',
    ),
  );
  final didResolver = CachedDidResolver(
    resolverAddress: options.didResolverAddress,
    logger: logger,
  );
  final mediatorSDK = MeetingPlaceMediatorSDK(
    mediatorDid: config.mediatorDid,
    didResolver: didResolver,
    logger: LoggerAdapter(
      className: MeetingPlaceMediatorSDK.className,
      sdkName: mediatorSDKName,
      logger: DefaultMeetingPlaceMediatorSDKLogger(),
    ),
  );
  final connectionManager = ConnectionManager(
    keyRepository: keyRepository,
    logger: logger,
  );
  final mediatorService = MediatorService(
    mediatorSDK: mediatorSDK,
    keyRepository: keyRepository,
    logger: logger,
  );
  final channelService = ChannelService(
    channelRepository: effectiveChannelRepository,
  );
  final messageService = MessageService(
    connectionManager: connectionManager,
    didResolver: didResolver,
    mediatorService: mediatorService,
    channelService: channelService,
    controlPlaneSDK: sdk.discovery,
    logger: logger,
  );
  final errorHandler = SDKErrorHandler(logger: logger);
  final didcomm = DIDCommTransport(
    mediatorSDK: mediatorSDK,
    messageService: messageService,
    mediatorService: mediatorService,
    didResolver: didResolver,
    errorHandler: errorHandler,
    getDidManager: (did) =>
        connectionManager.getDidManagerForDid(effectiveWallet, did),
    defaultMediatorDid: config.mediatorDid,
    expectedMessageWrappingTypes: options.expectedMessageWrappingTypes,
  );

  return (sdk, didcomm);
}

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    env['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

Uri getMatrixHomeserver() =>
    switch (Platform.environment['MATRIX_HOMESERVER'] ??
    env['MATRIX_HOMESERVER']) {
      final s? => Uri.parse(s),
      _ => throw Exception('MATRIX_HOMESERVER not set in environment'),
    };

String getVodozemacLibraryPath() =>
    Platform.environment['VODOZEMAC_LIBRARY_PATH'] ??
    env['VODOZEMAC_LIBRARY_PATH'] ??
    (throw Exception('VODOZEMAC_LIBRARY_PATH not set in environment'));

/// Ensures the vodozemac native library is loaded before any Matrix client is
/// created. The CoreSDK now requires this (matrix E2EE is on by default), so
/// every integration test that spins up an SDK must initialize it first.
Future<void> ensureVodozemacInitialized() async {
  if (vod.isInitialized()) return;
  await vod.init(libraryPath: getVodozemacLibraryPath());
}

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}
