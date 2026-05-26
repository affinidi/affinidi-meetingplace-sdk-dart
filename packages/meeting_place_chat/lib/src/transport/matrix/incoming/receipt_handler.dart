import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import 'room_event_handler.dart';

/// Handles `m.receipt` events by marking the corresponding outgoing message
/// as delivered.
class ReceiptHandler implements RoomEventHandler {
  ReceiptHandler({
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required Map<String, String> serverEventIdToMessageId,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _serverEventIdToMessageId = serverEventIdToMessageId;

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final Map<String, String> _serverEventIdToMessageId;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final serverEventId = event.content['event_id'] as String;
    final localMessageId = _serverEventIdToMessageId[serverEventId];
    if (localMessageId == null) return;

    final message = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: localMessageId,
    );

    if (message == null || !message.isFromMe) return;
    if (message.status == ChatItemStatus.delivered) return;

    message.status = ChatItemStatus.delivered;
    await _chatRepository.updateMesssage(message);

    _chatStream.pushData(
      StreamData(event: const ChatMessageEvent(), chatItem: message),
    );
  }
}
