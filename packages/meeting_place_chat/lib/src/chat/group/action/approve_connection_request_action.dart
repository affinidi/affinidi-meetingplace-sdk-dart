import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../transport/matrix/outgoing/outgoing.dart';
import '../../../loggers/top_and_tail_extension.dart';
import 'group_action.dart';

class ApproveConnectionRequestAction implements GroupAction<Group> {
  ApproveConnectionRequestAction(this._chatSDK, {required this.message});

  final GroupChatSDK _chatSDK;
  final ConciergeMessage message;

  @override
  Future<Group> execute() async {
    _requireGroupOwner();

    final channel = await _chatSDK.coreSDK.getChannelByOtherPartyPermanentDid(
      message.data['memberDid'] as String,
    );

    if (channel == null) {
      const error = 'Channel does not exist';
      _chatSDK.logger.error(error, name: 'approveConnectionRequest');
      throw Exception(error);
    }

    await _chatSDK.coreSDK.approveConnectionRequest(channel: channel);

    final updatedGroup = (await _chatSDK.coreSDK.getGroupById(
      _chatSDK.group.id,
    ))!;
    await _chatSDK.coreSDK.sendMessage(
      GroupDetailsUpdateRoomEvent(
        senderDid: _chatSDK.did,
        roomId: _chatSDK.roomId,
        group: updatedGroup,
      ),
    );

    message.status = ChatItemStatus.confirmed;
    await _chatSDK.chatRepository.updateMesssage(message);
    _chatSDK.chatStream.pushData(StreamData(chatItem: message));

    final chatItem = await _chatSDK.chatRepository.createMessage(
      EventMessage.awaitingGroupMember(
        chatId: _chatSDK.chatId,
        groupDid: updatedGroup.did,
        memberDid: channel.otherPartyPermanentChannelDid!,
        memberCard: channel.otherPartyContactCard!.toJson(),
      ),
    );

    _chatSDK.logger.info(
      'Completed approving connection request for member: '
      '${channel.otherPartyPermanentChannelDid?.topAndTail()}',
      name: 'approveConnectionRequest',
    );

    _chatSDK.chatStream.pushData(StreamData(chatItem: chatItem));

    return updatedGroup;
  }

  void _requireGroupOwner() {
    if (_chatSDK.isGroupOwner) return;
    _chatSDK.logger.error(
      'Only group owners can approve connection requests.',
      name: 'approveConnectionRequest',
    );
    throw Exception('Only group owners are allowed to perform this action');
  }
}
