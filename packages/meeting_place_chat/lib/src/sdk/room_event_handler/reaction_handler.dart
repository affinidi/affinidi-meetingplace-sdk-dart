import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import 'incoming_reaction_state_store.dart';
import 'room_event_handler.dart';

/// Handles `m.reaction` events by appending the reaction to its target
/// message and remembering the event so a later redaction can undo it.
class ReactionHandler implements RoomEventHandler {
  ReactionHandler({
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required Map<String, String> serverEventIdToMessageId,
    required IncomingReactionStateStore reactionStateStore,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _serverEventIdToMessageId = serverEventIdToMessageId,
       _reactionStateStore = reactionStateStore;

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final Map<String, String> _serverEventIdToMessageId;
  final IncomingReactionStateStore _reactionStateStore;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
    final targetEventId = relatesTo?['event_id'] as String?;
    final reaction = relatesTo?['key'] as String?;
    if (targetEventId == null || reaction == null) return;

    final messageId = _serverEventIdToMessageId[targetEventId] ?? targetEventId;
    final message = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: messageId,
    );
    if (message == null || message is! Message) return;

    if (message.reactions.contains(reaction)) return;

    message.reactions.add(reaction);
    await _chatRepository.updateMesssage(message);
    _chatStream.pushData(StreamData(chatItem: message));
    _reactionStateStore.register(
      eventId: event.id,
      messageId: messageId,
      reaction: reaction,
    );
  }
}
