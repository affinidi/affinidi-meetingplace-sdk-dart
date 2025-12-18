import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../fixtures/sdk.dart';
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage/in_memory_storage.dart';

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
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
    contactCardParsers: [ContactCardVcardParser()],
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
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}
