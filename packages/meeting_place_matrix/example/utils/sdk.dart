import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    env['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

Uri getMatrixHomeserver() => switch (
        Platform.environment['MATRIX_HOMESERVER'] ?? env['MATRIX_HOMESERVER']) {
      final s? => Uri.parse(s),
      _ => throw Exception('MATRIX_HOMESERVER not set in environment'),
    };

String getVodozemacLibraryPath() =>
    Platform.environment['VODOZEMAC_LIBRARY_PATH'] ??
    env['VODOZEMAC_LIBRARY_PATH'] ??
    (throw Exception('VODOZEMAC_LIBRARY_PATH not set in environment'));

Future<DatabaseApi> _openMatrixDatabase(MatrixDatabaseContext context) async {
  sqfliteFfiInit();
  final directory = Directory(
    '${Directory.systemTemp.path}/meeting_place_chat_example_matrix',
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
      deviceId: const Uuid().v4(),
    );

RepositoryConfig getRepositoryConfig() {
  final storage = InMemoryStorage();
  return RepositoryConfig(
    connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
    groupRepository: GroupRepositoryImpl(storage: storage),
    channelRepository: ChannelRepositoryImpl(storage: storage),
    keyRepository: KeyRepositoryImpl(storage: storage),
  );
}

Future<MeetingPlaceMatrixSDK> initMatrixSDK({required Wallet wallet}) =>
    MeetingPlaceMatrixSDK.create(
      wallet: wallet,
      repositoryConfig: getRepositoryConfig(),
      config: getMatrixConfig(),
      logger: DefaultMeetingPlaceCoreSDKLogger(),
    );
