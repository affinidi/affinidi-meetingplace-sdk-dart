import 'package:meeting_place_core/meeting_place_core.dart';
import '../core/chat_history_service.dart';
import '../service/chat_stream.dart';

class ChatGroupDetailsUpdateHandler {
  ChatGroupDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatHistoryService chatHistoryService,
    required ChatStream streamManager,
  })  : _coreSDK = coreSDK,
        _chatHistoryService = chatHistoryService,
        _chatStreamManager = streamManager;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatHistoryService _chatHistoryService;
  final ChatStream _chatStreamManager;

  Future<Group> handle({
    required Group group,
    required PlainTextMessage message,
    required String chatId,
  }) async {
    final updatedGroup = await _updateGroupMembersFromMessage(
      group: group,
      message: message,
      chatId: chatId,
    );
    await _coreSDK.updateGroup(updatedGroup);
    return updatedGroup;
  }

  Future<Group> _updateGroupMembersFromMessage({
    required Group group,
    required PlainTextMessage message,
    required String chatId,
  }) async {
    final membersFromMessage = (message.body!['members'] as List<dynamic>)
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
      final chatItem =
          await _chatHistoryService.createGroupMemberJoinedGroupEventMessage(
        chatId: chatId,
        groupDid: group.did,
        memberDid: newMember['did'] as String,
        memberCard: _cardFromMessage(newMember),
      );
      _chatStreamManager.pushData(StreamData(chatItem: chatItem));
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
          card: _cardFromMessage(member),
        );
      }).toList(),
    );

    _chatStreamManager.pushData(StreamData(plainTextMessage: message));
    return updatedGroup;
  }

  ContactCard _cardFromMessage(Map<String, dynamic> message) {
    return ContactCard.fromJson(
      message['card'] as Map<String, dynamic>,
    );
  }
}
