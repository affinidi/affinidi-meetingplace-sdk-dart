import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../utils/sdk.dart';
import 'repository/chat_repository_impl.dart';
import 'storage/in_memory_storage.dart';
import 'storage/storage_interface.dart';

class SDKFixture {
  static Future<MeetingPlaceChatSDK> initIndividualChatSDK({
    required MeetingPlaceCoreSDK coreSDK,
    required String did,
    required String otherPartyDid,
    required ChannelRepository channelRepository,
    VCard? vCard,
    VCard? otherPartyVCard,
    VCard? channelVCard,
    IStorage? existingStorage,
    ChatSDKOptions? options,
  }) async {
    final storage = existingStorage ?? InMemoryStorage();
    final channel = Channel(
      offerLink: const Uuid().v4(),
      publishOfferDid: '',
      mediatorDid: getMediatorDid(),
      status: ChannelStatus.inaugaurated,
      vCard: channelVCard,
      otherPartyVCard: otherPartyVCard,
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
        vCard: vCard,
        mediatorDid: getMediatorDid(),
        chatRepository: ChatRepositoryImpl(storage: storage),
        options: options ??
            ChatSDKOptions(
                chatPresenceSendInterval: const Duration(seconds: 3)),
        channelEntity: channel,
      ),
    );
  }

  static Future<MeetingPlaceChatSDK> initGroupChatSDK({
    required MeetingPlaceCoreSDK coreSDK,
    required String did,
    required String otherPartyDid,
    required Group group,
    required ChannelRepository channelRepository,
    VCard? vCard,
    IStorage? existingStorage,
  }) async {
    final storage = existingStorage ?? InMemoryStorage();
    final channel = Channel(
      offerLink: group.offerLink,
      publishOfferDid: '',
      mediatorDid: getMediatorDid(),
      status: ChannelStatus.inaugaurated,
      vCard: vCard,
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
        vCard: vCard,
        chatRepository: ChatRepositoryImpl(storage: storage),
        options: ChatSDKOptions(
            chatPresenceSendInterval: const Duration(seconds: 3)),
        channelEntity: channel,
      ),
    );
  }
}
