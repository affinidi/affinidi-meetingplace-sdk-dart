import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ssi/ssi.dart';
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

Future<Database> _openMatrixDatabase(MatrixDatabaseContext context) async {
  sqfliteFfiInit();
  final directory = Directory(
    '${Directory.systemTemp.path}/meeting_place_chat_example_matrix',
  );
  await directory.create(recursive: true);
  return databaseFactoryFfi.openDatabase(
    '${directory.path}/${context.databaseName}.sqlite',
  );
}

MatrixConfig getMatrixConfig() => MatrixConfig(
      homeserver: getMatrixHomeserver(),
      databaseFactory: const CallbackMatrixDatabaseFactory(
        openDatabase: _openMatrixDatabase,
      ),
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

Future<MeetingPlaceCoreSDK> initSDK({required Wallet wallet}) async {
  return MeetingPlaceCoreSDK.create(
    wallet: wallet,
    repositoryConfig: getRepositoryConfig(),
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
    matrixConfig: getMatrixConfig(),
    logger: DefaultMeetingPlaceCoreSDKLogger(),
  );
}
