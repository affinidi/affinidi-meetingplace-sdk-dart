import 'package:meeting_place_core/meeting_place_core.dart';

import '../chat_history_service.dart';
import '../../../event/chat_event.dart';
import '../../../event/chat_event_conversion.dart';
import '../../../event/chat_stream.dart';
import '../../../event/stream_data.dart';
import '../../../transport/matrix/matrix_user_id_cache.dart';
import '../../../transport/matrix/incoming/room_event_handler.dart';

class GroupDetailsUpdateHandler implements RoomEventHandler {
  GroupDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatHistoryService chatHistoryService,
    required ChatStream streamManager,
    required MatrixUserIdCache didCache,
    required String chatId,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _coreSDK = coreSDK,
       _chatHistoryService = chatHistoryService,
       _streamManager = streamManager,
       _didCache = didCache,
       _chatId = chatId,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatHistoryService _chatHistoryService;
  final ChatStream _streamManager;
  final MatrixUserIdCache _didCache;
  final String _chatId;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final updatedGroup = await _updateGroupMembers(
      group: _getGroup(),
      body: event.content,
      chatEvent: event.toChatEvent(),
    );
    await _coreSDK.updateGroup(updatedGroup);
    _setGroup(updatedGroup);
    _didCache.registerAll(updatedGroup.members.map((m) => m.did));
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
      final chatItem = await _chatHistoryService
          .createGroupMemberJoinedGroupEventMessage(
            chatId: _chatId,
            groupDid: group.did,
            memberDid: newMember['did'] as String,
            memberCard: _cardFromMember(newMember),
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
          contactCard: _cardFromMember(member),
        );
      }).toList(),
    );

    _streamManager.pushData(StreamData(event: chatEvent));
    return updatedGroup;
  }

  ContactCard _cardFromMember(Map<String, dynamic> member) {
    return ContactCard.fromJson(member['contact_card'] as Map<String, dynamic>);
  }
}
