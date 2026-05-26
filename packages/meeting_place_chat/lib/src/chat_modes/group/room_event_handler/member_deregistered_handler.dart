import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../repository/chat_history_service.dart';
import '../../../events/chat_event_conversion.dart';
import '../../../stream/chat_stream.dart';
import '../../../events/stream_data.dart';
import '../../../transport/matrix/matrix_user_id_cache.dart';
import '../../../transport/matrix/incoming/room_event_handler.dart';

class MemberDeregisteredHandler implements RoomEventHandler {
  MemberDeregisteredHandler({
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
    final senderDid = _didCache.resolve(event.userId);
    if (senderDid == null) return;

    final group = _getGroup();
    final member = group.members.firstWhere(
      (member) => member.did == senderDid,
      orElse: () => throw Exception('Member not found in group'),
    );

    if (member.status == GroupMemberStatus.deleted) return;

    member.status = GroupMemberStatus.deleted;
    await _coreSDK.updateGroup(group);
    _setGroup(group);

    final chatItem = await _chatHistoryService
        .createGroupMemberLeftGroupEventMessage(
          chatId: _chatId,
          groupDid: group.did,
          memberDid: senderDid,
          memberCard: member.contactCard,
        );

    _streamManager.pushData(
      StreamData(event: event.toChatEvent(), chatItem: chatItem),
    );
  }
}
