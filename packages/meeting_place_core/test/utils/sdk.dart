import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ssi/ssi.dart';

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
  final storage = InMemoryStorage();
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
    config: getMatrixConfig(),
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

Uri getMatrixHomeserver() =>
    switch (Platform.environment['MATRIX_HOMESERVER'] ??
    env['MATRIX_HOMESERVER']) {
      final s? => Uri.parse(s),
      _ => throw Exception('MATRIX_HOMESERVER not set in environment'),
    };

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}
