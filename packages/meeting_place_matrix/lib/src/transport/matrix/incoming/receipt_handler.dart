import 'package:meeting_place_chat/meeting_place_chat.dart';
import '../../../../meeting_place_matrix.dart';

/// Handles `m.receipt` events by marking the corresponding outgoing message
/// as delivered.
class ReceiptHandler {
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

  Future<void> handle(MatrixRoomEvent event) async {
    final serverEventId = event.content['event_id'] as String;
    final localMessageId = _serverEventIdToMessageId[serverEventId];
    if (localMessageId == null) return;

    final target = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: localMessageId,
    );
    if (target == null || !target.isFromMe) return;

    // Matrix `m.read` is cumulative: it acks the named event and every
    // earlier message from the same sender. Walk back over our own
    // outgoing messages with status `sent` and mark them delivered too.
    final allMessages = await _chatRepository.listMessages(_chatId);
    final cutoff = target.dateCreated;
    final toMark = allMessages
        .whereType<Message>()
        .where(
          (m) =>
              m.isFromMe &&
              m.status == ChatItemStatus.sent &&
              !m.dateCreated.isAfter(cutoff),
        )
        .toList();

    for (final message in toMark) {
      message.status = ChatItemStatus.delivered;
      await _chatRepository.updateMesssage(message);
      _chatStream.pushData(
        StreamData(event: const ChatMessageEvent(), chatItem: message),
      );
    }
  }
}
