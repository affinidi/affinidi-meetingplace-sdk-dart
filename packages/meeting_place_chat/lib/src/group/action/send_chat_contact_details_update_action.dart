import 'dart:async';

import '../../../meeting_place_chat.dart';
import '../../core/outgoing_message/outgoing_message.dart';

/// Confirms an approved profile update by:
///
/// 1. updating the local copy of the group with the new contact card,
/// 2. persisting the group via `coreSDK.updateGroup`,
/// 3. broadcasting a [ContactDetailsUpdateRoomEvent] so every other member can
///    mirror the change.
///
/// Identical for owners and regular members — the owner is just a member.
class SendChatContactDetailsUpdateAction {
  SendChatContactDetailsUpdateAction(this._chatSDK);

  static const String _logkey = 'SendChatContactDetailsUpdateAction';

  final GroupChatSDK _chatSDK;

  Future<void> execute(ConciergeMessage message) async {
    final card = _chatSDK.card;
    if (card == null) {
      const error = 'ContactCard missing for contact details update';
      _chatSDK.logger.error(error, name: _logkey);
      throw Exception(error);
    }

    final group = _chatSDK.group;
    final myMember = group.members.firstWhere((m) => m.did == _chatSDK.did);
    myMember.contactCard = card;
    await _chatSDK.coreSDK.updateGroup(group);

    unawaited(
      _chatSDK.coreSDK.sendMessage(
        ContactDetailsUpdateRoomEvent(
          senderDid: _chatSDK.did,
          roomId: _chatSDK.roomId,
          profileDetails: card.toJson(),
        ),
      ),
    );

    message.status = ChatItemStatus.confirmed;
    await _chatSDK.chatRepository.updateMesssage(message);

    _chatSDK.logger.info('Sent chat contact details update', name: _logkey);
    _chatSDK.chatStream.pushData(StreamData(chatItem: message));
  }
}
