import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:vodozemac/vodozemac.dart' as vod;
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage.dart';
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
  sqfliteFfiInit();

  if (!vod.isInitialized()) {
    await vod.init();
  }

  return MeetingPlaceCoreSDK.create(
    wallet: wallet,
    repositoryConfig: getRepositoryConfig(),
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
    logger: DefaultMeetingPlaceCoreSDKLogger(),
    matrixClientFactory: (did) async {
      // Each DID gets its own SQLite file so Olm identity keys are never
      // shared or overwritten between users on the same device.
      final key = md5.convert(utf8.encode(did)).toString();
      final database = await matrix.MatrixSdkDatabase.init(
        'matrix_$key',
        database: await databaseFactoryFfi.openDatabase(
          './data/matrix_$key.sqlite',
        ),
      );
      final client = matrix.Client('myapp_$key', database: database);
      client.homeserver = Uri.parse('http://localhost:9000');
      return client;
    },
  );
}
