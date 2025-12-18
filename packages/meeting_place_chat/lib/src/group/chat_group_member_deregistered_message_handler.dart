import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../core/chat_history_service.dart';
import '../service/chat_stream.dart';

class ChatGroupMemberDeregisteredMessageHandler {
  ChatGroupMemberDeregisteredMessageHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatHistoryService chatHistoryService,
    required ChatStream streamManager,
  }) : _coreSDK = coreSDK,
       _chatHistoryService = chatHistoryService,
       _streamManager = streamManager;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatHistoryService _chatHistoryService;
  final ChatStream _streamManager;

  Future<Group> handle({
    required String chatId,
    required Group group,
    required PlainTextMessage message,
  }) async {
    final groupId = message.body?['group_id'] as String;
    final memberDid = message.body?['member_did'] as String;

    if (groupId != group.id) {
      throw Exception('Group ids doesnt match');
    }

    final member = group.members.firstWhere(
      (member) => member.did == memberDid,
      orElse: () => throw Exception('Member not found in group'),
    );

    member.status = GroupMemberStatus.deleted;
    await _coreSDK.updateGroup(group);

    final chatItem = await _chatHistoryService
        .createGroupMemberLeftGroupEventMessage(
          chatId: chatId,
          groupDid: groupId,
          memberDid: memberDid,
          memberCard: member.contactCard,
        );

    _streamManager.pushData(StreamData(chatItem: chatItem));

    return group;
  }
}
