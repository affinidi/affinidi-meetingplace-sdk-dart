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
import 'package:ssi/ssi.dart';

import '../fixtures/sdk.dart';
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage/in_memory_storage.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['test/.env']);

Config getConfig() => Config(
  mediatorDid: getMediatorDid(),
  controlPlaneDid: getControlPlaneDid(),
);

RepositoryConfig getRepositoryConfig([InMemoryStorage? storage]) {
  final s = storage ?? InMemoryStorage();
  return RepositoryConfig(
    connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: s),
    groupRepository: GroupRepositoryImpl(storage: s),
    channelRepository: ChannelRepositoryImpl(storage: s),
    keyRepository: KeyRepositoryImpl(storage: s),
  );
}

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
/// to the same wallet, key repository, and channel repository.
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
  final effectiveWallet = wallet ?? PersistentWallet(InMemoryKeyStore());
  final storage = InMemoryStorage();
  final keyRepository = KeyRepositoryImpl(storage: storage);
  final effectiveChannelRepository =
      channelRepository ?? ChannelRepositoryImpl(storage: storage);
  final config = getConfig();

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
    options: const MeetingPlaceCoreSDKOptions(
      expectedMessageWrappingTypes: [
        MessageWrappingType.authcryptSignPlaintext,
        MessageWrappingType.authcryptPlaintext,
      ],
    ),
  );

  if (!withoutDevice) {
    await sdk.registerForPushNotifications(
      deviceToken ?? SDKFixture.generateRandomDeviceToken(),
    );
  }

  if (!buildDidcomm) {
    return (sdk, null);
  }

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
    controlPlaneSDK: sdk.controlPlaneSDK,
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

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}
