import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../logger/top_and_tail_extension.dart';
import '../../../transport/matrix/outgoing/outgoing.dart';
import '../group_matrix_chat_sdk.dart';
import 'group_action.dart';

class RejectConnectionRequestAction implements GroupAction<Group> {
  RejectConnectionRequestAction(this._chatSDK, {required this.message});

  final GroupMatrixChatSDK _chatSDK;
  final ConciergeMessage message;

  @override
  Future<Group> execute() async {
    if (!_chatSDK.isGroupOwner) {
      _chatSDK.logger.error(
        'Only group owners can reject connection requests.',
        name: 'rejectConnectionRequest',
      );
      throw Exception(
        'Only group owners are allowed to reject connection requests',
      );
    }

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
    await GroupDetailsUpdateSender(coreSDK: _chatSDK.coreSDK).send(
      channel: await _chatSDK.getChannel(),
      senderDid: _chatSDK.did,
      group: updatedGroup,
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
}
