import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../transport/matrix/outgoing/outgoing.dart';
import '../../../utils/top_and_tail_extension.dart';
import 'group_action.dart';

class RejectConnectionRequestAction implements GroupAction<Group> {
  RejectConnectionRequestAction(this._chatSDK, {required this.message});

  final GroupChatSDK _chatSDK;
  final ConciergeMessage message;

  @override
  Future<Group> execute() async {
    _requireGroupOwner();

    final channel = await _chatSDK.coreSDK.getChannelByDid(
      message.data['memberDid'] as String,
    );

    if (channel == null) {
      const error = 'Channel does not exist';
      _chatSDK.logger.error(error, name: 'rejectConnectionRequest');
      throw Exception(error);
    }

    final updatedGroup = await _chatSDK.coreSDK.rejectConnectionRequest(
      channel: channel,
    );
    await _chatSDK.coreSDK.sendMessage(
      GroupDetailsUpdateRoomEvent(
        senderDid: _chatSDK.did,
        roomId: _chatSDK.roomId,
        group: updatedGroup,
      ),
    );

    message.status = ChatItemStatus.confirmed;
    await _chatSDK.chatRepository.updateMesssage(message);

    _chatSDK.logger.info(
      'Completed rejecting connection request for member: '
      '${channel.otherPartyPermanentChannelDid?.topAndTail()}',
      name: 'rejectConnectionRequest',
    );

    _chatSDK.chatStream.pushData(StreamData(chatItem: message));

    return updatedGroup;
  }

  void _requireGroupOwner() {
    if (_chatSDK.isGroupOwner) return;
    _chatSDK.logger.error(
      'Only group owners can reject connection requests.',
      name: 'rejectConnectionRequest',
    );
    throw Exception('Only group owners are allowed to perform this action');
  }
}
