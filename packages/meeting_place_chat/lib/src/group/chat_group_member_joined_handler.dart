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
    required MediatorMessage message,
    required String chatId,
    required String groupDid,
    required bool isGroupOwner,
    required List<ChatProtocol> memberJoinedIndicator,
  }) async {
    if (!isGroupOwner) return;

    final messageType = ChatProtocol.byValue(
      message.plainTextMessage.type.toString(),
    );
    if (messageType == null || !memberJoinedIndicator.contains(messageType)) {
      return;
    }

    final senderDid = message.fromDid ?? message.plainTextMessage.from;
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
              eventMessage.data['memberDid'] == senderDid,
        );

    if (matchingMessage == null) return;

    final memberDid = matchingMessage.data['memberDid'];
    if (memberDid is! String) {
      throw StateError(
        'Expected awaitingGroupMemberToJoin event to include memberDid.',
      );
    }

    final contactCardData = matchingMessage.data['contactCard'];
    if (contactCardData is! Map<String, dynamic>) {
      throw StateError(
        'Expected awaitingGroupMemberToJoin event to include contactCard data.',
      );
    }

    matchingMessage.status = ChatItemStatus.confirmed;
    await _chatRepository.updateMesssage(matchingMessage);
    _streamManager.pushData(StreamData(chatItem: matchingMessage));

    final chatItem = await _chatHistoryService
        .createGroupMemberJoinedGroupEventMessage(
          chatId: chatId,
          groupDid: groupDid,
          memberDid: memberDid,
          memberCard: ContactCard.fromJson(contactCardData),
        );

    _streamManager.pushData(StreamData(chatItem: chatItem));
  }
}
