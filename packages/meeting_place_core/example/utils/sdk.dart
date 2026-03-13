import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    env['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

getRepositoryConfig() {
  final storage = InMemoryStorage();
  return RepositoryConfig(
    connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
    groupRepository: GroupRepositoryImpl(storage: storage),
    channelRepository: ChannelRepositoryImpl(storage: storage),
    keyRepository: KeyRepositoryImpl(storage: storage),
  );
}

Future<MeetingPlaceCoreSDK> initSDK({required Wallet wallet}) async {
  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase('./data/database.sqlite');

  final database = await matrix.MatrixSdkDatabase.init(
    'matrix_client',
    database: db,
  );

  final matrixClient = matrix.Client('myapp', database: database);
  matrixClient.homeserver = Uri.parse('http://localhost:9000');

  return MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: getRepositoryConfig(),
      mediatorDid: getMediatorDid(),
      controlPlaneDid: getControlPlaneDid(),
      logger: DefaultMeetingPlaceCoreSDKLogger(),
      matrixClient: matrixClient);
}
