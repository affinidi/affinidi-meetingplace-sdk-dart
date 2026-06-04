import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:ssi/ssi.dart';

import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'repository/r_card_repository_impl.dart';
import 'repository/vrc_repository_impl.dart';
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

RepositoryConfig _coreRepositoryConfig({required InMemoryStorage storage}) {
  return RepositoryConfig(
    connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
    groupRepository: GroupRepositoryImpl(storage: storage),
    channelRepository: ChannelRepositoryImpl(storage: storage),
    keyRepository: KeyRepositoryImpl(storage: storage),
  );
}

/// Initialises a [MeetingPlaceCoreSDK] + [MeetingPlaceCredentialsSDK] pair
/// backed by in-memory storage and keyed by the provided [wallet].
///
/// Both SDKs are returned as a Dart record so callers can use the core SDK
/// for connection management and the credentials SDK for R-Card / VRC flows.
Future<(MeetingPlaceCoreSDK, MeetingPlaceCredentialsSDK)> initSDKBundle({
  required Wallet wallet,
}) async {
  final storage = InMemoryStorage();

  final coreSDK = await MeetingPlaceCoreSDK.create(
    wallet: wallet,
    repositoryConfig: _coreRepositoryConfig(storage: storage),
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
    logger: DefaultMeetingPlaceCoreSDKLogger(),
  );

  final credentialsSDK = MeetingPlaceCredentialsSDK(
    coreSDK: coreSDK,
    rCardRepository: RCardRepositoryImpl(),
    vrcRepository: VrcRepositoryImpl(),
  );

  return (coreSDK, credentialsSDK);
}
