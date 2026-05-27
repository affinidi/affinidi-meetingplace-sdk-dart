import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';

class GroupDetailsUpdateHandler implements ChatEventHandler {
  GroupDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required void Function(Iterable<String>) registerMemberDids,
    required String chatId,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _streamManager = streamManager,
       _registerMemberDids = registerMemberDids,
       _chatId = chatId,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final void Function(Iterable<String>) _registerMemberDids;
  final String _chatId;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final updatedGroup = await _updateGroupMembers(
      group: _getGroup(),
      body: event.content,
      chatEvent: ChatGroupMembersUpdatedEvent(groupDid: _getGroup().did),
    );
    await _coreSDK.updateGroup(updatedGroup);
    _setGroup(updatedGroup);
    _registerMemberDids(updatedGroup.members.map((m) => m.did));
  }

  Future<Group> _updateGroupMembers({
    required Group group,
    required Map<String, dynamic> body,
    required ChatEvent chatEvent,
  }) async {
    final membersFromMessage = (body['members'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final knownMembers = group.members.map((member) => member.did).toSet();
    final newMembers = membersFromMessage
        .where((member) {
          final status = GroupMemberStatus.values.byName(
            member['status'] as String,
          );
          return !knownMembers.contains(member['did']) &&
              status == GroupMemberStatus.approved;
        })
        .toList()
        .cast<Map<String, dynamic>>();

    for (final newMember in newMembers) {
      final chatItem = await _chatRepository.createMessage(
        EventMessage.groupMemberJoined(
          chatId: _chatId,
          groupDid: group.did,
          memberDid: newMember['did'] as String,
          memberCard: newMember['contact_card'] as Map<String, dynamic>,
        ),
      );
      _streamManager.pushData(StreamData(chatItem: chatItem));
    }

    final updatedGroup = group.copyWith(
      members: membersFromMessage.map((member) {
        return GroupMember(
          did: member['did'] as String,
          dateAdded: DateTime.parse(member['date_added'] as String),
          status: GroupMemberStatus.values.byName(member['status'] as String),
          publicKey: member['public_key'] as String,
          membershipType: GroupMembershipType.values.byName(
            member['membership_type'] as String,
          ),
          contactCard: ContactCard.fromJson(
            member['contact_card'] as Map<String, dynamic>,
          ),
        );
      }).toList(),
    );

    _streamManager.pushData(StreamData(event: chatEvent));
    return updatedGroup;
  }
}
