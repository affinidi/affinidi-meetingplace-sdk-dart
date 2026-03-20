import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:matrix/matrix.dart' as matrix;
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

String getMatrixHomeserverUrl() =>
    Platform.environment['MATRIX_HOMESERVER_URL'] ??
    env['MATRIX_HOMESERVER_URL'] ??
    'http://localhost:9000';

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
  // Initialize SQLite database for Matrix client (stores local sync data)
  // This is separate from the Synapse server database in ai-mpx-matrix
  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase('./data/matrix_client.sqlite');

  // Initialize Matrix SDK database wrapper
  final database = await matrix.MatrixSdkDatabase.init(
    'meeting_place_matrix_client',
    database: db,
  );

  // Create Matrix client that connects to Synapse homeserver
  final matrixClient = matrix.Client('MeetingPlaceClient', database: database);
  matrixClient.homeserver = Uri.parse(getMatrixHomeserverUrl());

  return MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: getRepositoryConfig(),
      mediatorDid: getMediatorDid(),
      controlPlaneDid: getControlPlaneDid(),
      matrixClientFactory: (_) async => matrixClient,
      logger: DefaultMeetingPlaceCoreSDKLogger());
}
