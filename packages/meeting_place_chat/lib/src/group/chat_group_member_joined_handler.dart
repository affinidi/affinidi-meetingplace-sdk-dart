import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';
import '../core/chat_history_service.dart';

class ChatGroupMemberJoinedHandler {
  ChatGroupMemberJoinedHandler({
    required ChatRepository chatRepository,
    required ChatHistoryService chatHistoryService,
    required ChatStream streamManager,
  }) : _chatRepository = chatRepository,
       _chatHistoryService = chatHistoryService,
       _streamManager = streamManager;

  final ChatRepository _chatRepository;
  final ChatHistoryService _chatHistoryService;
  final ChatStream _streamManager;

  Future<void> handle({
    required PlainTextMessage message,
    required String chatId,
    required String groupDid,
  }) async {
    final senderDid = message.from;
    if (senderDid == null) return;

    // TODO: keep target list in memory to not always iterate through all
    // messages
    final allMessages = await _chatRepository.listMessages(chatId);
    final matchingMessage = allMessages
        .whereType<EventMessage>()
        .firstWhereOrNull(
          (eventMessage) =>
              eventMessage.status != ChatItemStatus.confirmed &&
              eventMessage.eventType ==
                  EventMessageType.awaitingGroupMemberToJoin &&
              (eventMessage.data['memberDid'] == senderDid ||
                  eventMessage.data['memberDid'] == message.body?['from_did']),
        );

    if (matchingMessage == null) return;

    matchingMessage.status = ChatItemStatus.confirmed;
    await _chatRepository.updateMesssage(matchingMessage);
    _streamManager.pushData(StreamData(chatItem: matchingMessage));

    final chatItem = await _chatHistoryService
        .createGroupMemberJoinedGroupEventMessage(
          chatId: chatId,
          groupDid: groupDid,
          memberDid: matchingMessage.data['memberDid'] as String,
          memberCard: ContactCard.fromJson(
            matchingMessage.data['contactCard'] as Map<String, dynamic>,
          ),
        );

    _streamManager.pushData(StreamData(chatItem: chatItem));
  }
}
