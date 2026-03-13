import 'package:meeting_place_core/meeting_place_core.dart';

import '../core/chat_history_service.dart';
import '../service/chat_stream.dart';

class ChatGroupDeletionHandler {
  ChatGroupDeletionHandler({
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
    required Group group,
    required PlainTextMessage message,
    required String chatId,
  }) async {
    if (!group.isDeleted) {
      group.markAsDeleted();
      await _coreSDK.updateGroup(group);

      final chatItem = await _chatHistoryService.createGroupDeletedEventMessage(
        chatId: chatId,
        groupDid: group.did,
      );

      _streamManager.pushData(StreamData(chatItem: chatItem));
    }
    return group;
  }
}
