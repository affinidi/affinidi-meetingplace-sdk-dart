import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage.dart';

String getControlPlaneDid() =>
    'did:web:control-flower.meetingplace.dev.affinidi.io';
// Platform.environment['CONTROL_PLANE_DID'] ??
// (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() => 'did:web:euw1.mediator.affinidi.io:.well-known';
// Platform.environment['MEDIATOR_DID'] ??
// (throw Exception('MEDIATOR_DID not set in environment'));

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
  return MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: getRepositoryConfig(),
      mediatorDid: getMediatorDid(),
      controlPlaneDid: getControlPlaneDid(),
      logger: DefaultMeetingPlaceCoreSDKLogger());
}
