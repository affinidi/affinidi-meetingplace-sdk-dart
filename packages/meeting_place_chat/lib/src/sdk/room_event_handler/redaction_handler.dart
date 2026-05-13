import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import 'incoming_reaction_state_store.dart';
import 'room_event_handler.dart';

/// Handles `m.room.redaction` events that revoke a previously received
/// reaction, removing it from the target message.
class RedactionHandler implements RoomEventHandler {
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

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final redactedEventId = event.content['redacts'] as String?;
    if (redactedEventId == null) return;

    final entry = _reactionStateStore.popByEventId(redactedEventId);
    if (entry == null) return;

    final message = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: entry.messageId,
    );
    if (message == null || message is! Message) return;

    if (!message.reactions.remove(entry.reaction)) return;

    await _chatRepository.updateMesssage(message);
    _chatStream.pushData(StreamData(chatItem: message));
  }
}
