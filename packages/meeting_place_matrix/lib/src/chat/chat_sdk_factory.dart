import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/chat/individual/individual_didcomm_chat_sdk.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'group/group_matrix_chat_sdk.dart';
import 'individual/individual_matrix_chat_sdk.dart';

/// Creates the appropriate [MeetingPlaceChatSDK] implementation for [channel].
///
/// Groups always use Matrix. Individual channels dispatch on
/// [Channel.transport] between [IndividualMatrixChatSDK] and
/// [IndividualDidcommChatSDK].
Future<MeetingPlaceChatSDK> initialiseChatFromChannel(
  Channel channel, {
  required MeetingPlaceCoreSDK coreSDK,
  required ChatRepository chatRepository,
  required MeetingPlaceChatSDKOptions options,
  ContactCard? card,
  MeetingPlaceChatSDKLogger? logger,
}) async {
  if (channel.type == ChannelType.group) {
    final group =
        await coreSDK.getGroupByOfferLink(channel.offerLink) ??
        (throw Exception('Group not found'));

    return GroupMatrixChatSDK(
      coreSDK: coreSDK,
      group: group,
      did: channel.permanentChannelDid!,
      otherPartyDid: channel.otherPartyPermanentChannelDid!,
      mediatorDid: channel.mediatorDid,
      chatRepository: chatRepository,
      options: options,
      card: card,
      logger: logger,
    );
  }

  return switch (channel.transport) {
    ChannelTransport.matrix => IndividualMatrixChatSDK(
      coreSDK: coreSDK,
      did: channel.permanentChannelDid!,
      otherPartyDid: channel.otherPartyPermanentChannelDid!,
      mediatorDid: channel.mediatorDid,
      chatRepository: chatRepository,
      options: options,
      card: card,
      logger: logger,
    ),
    ChannelTransport.didcomm => IndividualDidcommChatSDK(
      coreSDK: coreSDK,
      did: channel.permanentChannelDid!,
      otherPartyDid: channel.otherPartyPermanentChannelDid!,
      mediatorDid: channel.mediatorDid,
      chatRepository: chatRepository,
      options: options,
      card: card,
      logger: logger,
    ),
  };
}
