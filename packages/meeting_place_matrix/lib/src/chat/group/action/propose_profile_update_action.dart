import 'package:collection/collection.dart';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import '../factory/profile_update_concierge_factory.dart';
import '../group_matrix_chat_sdk.dart';
import 'group_action.dart';

/// Proposes a profile update by creating a local
/// [ConciergeMessageType.permissionToUpdateProfile] concierge that the user
/// must confirm before the new contact card is shared with the group. No room
/// event is emitted at this stage — the broadcast happens only after the user
/// approves via [GroupMatrixChatSDK.sendChatContactDetailsUpdate].
///
/// Identical for owners and regular members.
class ProposeProfileUpdateAction implements GroupAction<void> {
  ProposeProfileUpdateAction(this._chatSDK);

  static const String _logkey = 'ProposeProfileUpdateAction';

  final GroupMatrixChatSDK _chatSDK;

  @override
  Future<void> execute() async {
    final card = _chatSDK.currentContactCard;
    if (card == null) {
      _chatSDK.logger.warning(
        'ContactCard is null. Skipping profile update proposal.',
        name: _logkey,
      );
      return;
    }

    final channel = await _chatSDK.getChannel();
    if (channel.contactCard == null || card.equals(channel.contactCard!)) {
      _chatSDK.logger.info(
        'ContactCard has not changed. Skipping profile update proposal.',
        name: _logkey,
      );
      return;
    }

    final existing = await _findPendingProfileUpdateConcierge();

    channel.contactCard = card;
    await _chatSDK.coreSDK.updateChannel(channel);

    if (existing != null) return;

    final conciergeMessage = await ProfileUpdateConciergeFactory(
      chatRepository: _chatSDK.chatRepository,
      logger: _chatSDK.logger,
    ).create(chatId: _chatSDK.chatId, senderDid: _chatSDK.did, card: card);

    _chatSDK.chatStream.pushData(StreamData(chatItem: conciergeMessage));
  }

  Future<ConciergeMessage?> _findPendingProfileUpdateConcierge() async {
    final messages = await _chatSDK.chatRepository.listMessages(
      _chatSDK.chatId,
    );
    return messages.whereType<ConciergeMessage>().firstWhereOrNull(
      (m) =>
          m.conciergeType == ConciergeMessageType.permissionToUpdateProfile &&
          m.status == ChatItemStatus.userInput,
    );
  }
}
