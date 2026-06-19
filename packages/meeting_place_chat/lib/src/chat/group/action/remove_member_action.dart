import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../logger/top_and_tail_extension.dart';
import 'group_action.dart';

/// Owner-initiated removal of a group member. The chat layer drives the
/// local-state update directly because the initiator already knows the outcome
/// and shouldn't have to wait for a Matrix echo (which is filtered out by
/// `excludeSelf`).
class RemoveMemberAction implements GroupAction<Group> {
  RemoveMemberAction(this._chatSDK, {required this.memberDid});

  final GroupMatrixChatSDK _chatSDK;
  final String memberDid;

  @override
  Future<Group> execute() async {
    if (!_chatSDK.isGroupOwner) {
      _chatSDK.logger.error(
        'Only group owners can remove members.',
        name: 'removeMember',
      );
      throw Exception('Only group owners are allowed to remove members');
    }

    final group = _chatSDK.group;
    final member = group.members.firstWhere(
      (m) => m.did == memberDid,
      orElse: () => throw Exception('Member not found in group'),
    );

    await _chatSDK.coreSDK.removeMemberFromGroup(
      groupId: group.id,
      memberDid: memberDid,
    );

    member.status = GroupMemberStatus.deleted;

    final chatItem = await _chatSDK.chatRepository.createMessage(
      EventMessage.groupMemberLeft(
        chatId: _chatSDK.chatId,
        groupDid: group.did,
        memberDid: memberDid,
        memberCard: member.contactCard.toJson(),
        reason: GroupMemberLeaveReason.kick,
      ),
    );

    _chatSDK.chatStream.pushData(
      StreamData(
        event: ChatMemberDeregisteredEvent(
          groupDid: group.did,
          memberDid: memberDid,
        ),
        chatItem: chatItem,
      ),
    );

    _chatSDK.logger.info(
      'Removed member ${memberDid.topAndTail()} from group ${group.id}',
      name: 'removeMember',
    );

    return group;
  }
}
