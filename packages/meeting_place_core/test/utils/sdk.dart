import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
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

Future<MeetingPlaceCoreSDK> initSDKInstance({
  Wallet? wallet,
  String? deviceToken,
  bool withoutDevice = false,
  ChannelRepository? channelRepository,
  bool enableMatrixEncryption = false,
}) async {
  final storage = InMemoryStorage();
  final matrixClient = await initMatrixClient(
    enableEncryptionRuntime: enableMatrixEncryption,
  );
  final sdk = await MeetingPlaceCoreSDK.create(
    wallet: wallet ?? PersistentWallet(InMemoryKeyStore()),
    repositoryConfig: RepositoryConfig(
      connectionOfferRepository: ConnectionOfferRepositoryImpl(
        storage: storage,
      ),
      groupRepository: GroupRepositoryImpl(storage: storage),
      keyRepository: KeyRepositoryImpl(storage: storage),
      channelRepository:
          channelRepository ?? ChannelRepositoryImpl(storage: storage),
    ),
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
    matrixClient: matrixClient,
  );

  if (!withoutDevice) {
    await sdk.registerForPushNotifications(
      deviceToken ?? SDKFixture.generateRandomDeviceToken(),
    );
  }

  return sdk;
}

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    env['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

String getMatrixHomeserver() =>
    Platform.environment['MATRIX_HOMESERVER'] ??
    env['MATRIX_HOMESERVER'] ??
    'http://localhost:9000';

String? getVodozemacLibraryPath() =>
    Platform.environment['VODOZEMAC_LIBRARY_PATH'] ??
    env['VODOZEMAC_LIBRARY_PATH'];

Future<matrix.Client> initMatrixClient({
  bool enableEncryptionRuntime = false,
}) async {
  sqfliteFfiInit();

  if (enableEncryptionRuntime && !vod.isInitialized()) {
    final libraryPath = getVodozemacLibraryPath();
    if (libraryPath == null || libraryPath.isEmpty) {
      throw StateError(
        'VODOZEMAC_LIBRARY_PATH must point to a built native vodozemac library directory when Matrix encryption is enabled in core integration tests.',
      );
    }

    await vod.init(libraryPath: libraryPath);
  }

  final tempDir = await Directory.systemTemp.createTemp(
    'meeting_place_core_matrix_',
  );
  final database = await matrix.MatrixSdkDatabase.init(
    'matrix_client',
    database: await databaseFactoryFfi.openDatabase(
      '${tempDir.path}/matrix.sqlite',
    ),
  );

  final client = matrix.Client(
    'meeting-place-core-test-${tempDir.uri.pathSegments.last}',
    database: database,
  );
  client.homeserver = Uri.parse(getMatrixHomeserver());

  return client;
}

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}
