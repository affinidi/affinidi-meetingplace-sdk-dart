import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import 'repository/channel_repository_impl.dart';
import 'repository/chat_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage/in_memory_storage.dart';
import 'storage/storage.dart';

Future<MeetingPlaceCoreSDK> initCoreSDKInstance({
  Wallet? wallet,
  GroupRepository? groupRepository,
  ChannelRepository? channelRepository,
}) async {
  final storage = InMemoryStorage();
  final sdk = await MeetingPlaceCoreSDK.create(
    wallet: wallet ?? PersistentWallet(InMemoryKeyStore()),
    repositoryConfig: RepositoryConfig(
      connectionOfferRepository: ConnectionOfferRepositoryImpl(
        storage: storage,
      ),
      groupRepository: groupRepository ?? GroupRepositoryImpl(storage: storage),
      keyRepository: KeyRepositoryImpl(storage: storage),
      channelRepository:
          channelRepository ?? ChannelRepositoryImpl(storage: storage),
    ),
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
  );

  await sdk.registerForPushNotifications(const Uuid().v4());
  return sdk;
}

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}

Future<MeetingPlaceChatSDK> initIndividualChatSDK({
  required MeetingPlaceCoreSDK coreSDK,
  required String did,
  required String otherPartyDid,
  required ChannelRepository channelRepository,
  ContactCard? card,
  ContactCard? otherPartyCard,
  ContactCard? channelCard,
  Storage? existingStorage,
  ChatSDKOptions? options,
}) async {
  final storage = existingStorage ?? InMemoryStorage();
  final channel = Channel(
    offerLink: const Uuid().v4(),
    publishOfferDid: '',
    mediatorDid: getMediatorDid(),
    status: ChannelStatus.inaugurated,
    contactCard: channelCard,
    otherPartyContactCard: otherPartyCard,
    type: ChannelType.individual,
    permanentChannelDid: did,
    otherPartyPermanentChannelDid: otherPartyDid,
  );

  await channelRepository.createChannel(channel);

  return MeetingPlaceChatSDK(
    sdk: IndividualChatSDK(
      coreSDK: coreSDK,
      did: did,
      otherPartyDid: otherPartyDid,
      card: card,
      mediatorDid: getMediatorDid(),
      chatRepository: ChatRepositoryImpl(storage: storage),
      options: options ??
          ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 3)),
    ),
  );
}

Future<MeetingPlaceChatSDK> initGroupChatSDK({
  required MeetingPlaceCoreSDK coreSDK,
  required String did,
  required String otherPartyDid,
  required Group group,
  required ChannelRepository channelRepository,
  ContactCard? card,
  Storage? existingStorage,
}) async {
  final storage = existingStorage ?? InMemoryStorage();
  final channel = Channel(
    offerLink: group.offerLink,
    publishOfferDid: '',
    mediatorDid: getMediatorDid(),
    status: ChannelStatus.inaugurated,
    contactCard: card,
    type: ChannelType.group,
    permanentChannelDid: did,
    otherPartyPermanentChannelDid: otherPartyDid,
  );

  await channelRepository.createChannel(channel);

  return MeetingPlaceChatSDK(
    sdk: GroupChatSDK(
      coreSDK: coreSDK,
      group: group,
      did: did,
      otherPartyDid: otherPartyDid,
      mediatorDid: getMediatorDid(),
      card: card,
      chatRepository: ChatRepositoryImpl(storage: storage),
      options:
          ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 3)),
    ),
  );
}

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));
