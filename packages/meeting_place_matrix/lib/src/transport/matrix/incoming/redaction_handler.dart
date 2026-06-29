import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../../../../meeting_place_matrix.dart';
import 'incoming_reaction_state_store.dart';

/// Handles `m.room.redaction` events. Redactions can target two things:
/// a previously received reaction (revoked → remove from target message)
/// or a previously received message (deleted by its sender → mark the
/// stored [Message] as `isDeleted`).
class RedactionHandler {
  RedactionHandler({
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required IncomingReactionStateStore reactionStateStore,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _reactionStateStore = reactionStateStore;

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final IncomingReactionStateStore _reactionStateStore;

  Future<void> handle(MatrixRoomEvent event) async {
    final redactedEventId = event.content['redacts'] as String?;
    if (redactedEventId == null) return;

    final entry = _reactionStateStore.popByEventId(redactedEventId);
    if (entry != null) {
      final message = await _chatRepository.getMessage(
        chatId: _chatId,
        messageId: entry.messageId,
      );
      if (message == null || message is! Message) return;

      // Remove only the reaction applied by the sender whose event was
      // redacted, not every reaction sharing the same emoji.
      final removed = message.reactions.remove(
        MessageReaction(emoji: entry.emoji, senderDid: entry.senderDid),
      );
      if (!removed) return;

      await _chatRepository.updateMesssage(message);
      _chatStream.pushData(StreamData(chatItem: message));
      return;
    }

    final message = await _findMessageByTransportId(redactedEventId);
    if (message == null) return;
    if (message.isDeleted) return;

    message.isDeleted = true;
    message.clearContent();
    await _chatRepository.updateMesssage(message);
    _chatStream.pushData(StreamData(chatItem: message));
  }

  Future<Message?> _findMessageByTransportId(String transportId) async {
    final items = await _chatRepository.listMessages(_chatId);
    for (final item in items) {
      if (item is Message && item.transportId == transportId) return item;
    }
    return null;
  }
}
