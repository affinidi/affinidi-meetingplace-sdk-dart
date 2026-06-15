import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import 'incoming_reaction_state_store.dart';

/// Handles `m.reaction` events by appending the reaction to its target
/// message and remembering the event so a later redaction can undo it.
class ReactionHandler {
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

  Future<void> handle(MatrixRoomEvent event) async {
    final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
    final targetEventId = relatesTo?['event_id'] as String?;
    final reaction = relatesTo?['key'] as String?;
    if (targetEventId == null || reaction == null) return;

    final message = await _resolveTargetMessage(targetEventId);
    if (message == null) return;

    // The target message is tombstoned for the local user. The reaction
    // is dropped on the floor — we don't mutate, don't push to the stream,
    // and don't register it for later redaction matching (because there is
    // no local state to undo).
    if (message.isDeleted || message.isDeletedLocally) return;

    if (message.reactions.contains(reaction)) return;

    message.reactions.add(reaction);
    await _chatRepository.updateMesssage(message);
    _chatStream.pushData(StreamData(chatItem: message));
    _reactionStateStore.register(
      eventId: event.id,
      messageId: message.messageId,
      reaction: reaction,
    );
  }

  /// Resolves the local [Message] targeted by a reaction's Matrix event id.
  ///
  /// The in-memory [_serverEventIdToMessageId] map only covers messages seen
  /// live this session, so it misses history and cross-session messages. Fall
  /// back to the persisted `transportId` (the Matrix event id) so reactions on
  /// older messages still resolve instead of being dropped.
  Future<Message?> _resolveTargetMessage(String targetEventId) async {
    final mappedId = _serverEventIdToMessageId[targetEventId];
    if (mappedId != null) {
      final mapped = await _chatRepository.getMessage(
        chatId: _chatId,
        messageId: mappedId,
      );
      if (mapped is Message) return mapped;
    }

    final direct = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: targetEventId,
    );
    if (direct is Message) return direct;

    final items = await _chatRepository.listMessages(_chatId);
    for (final item in items) {
      if (item is Message && item.transportId == targetEventId) return item;
    }
    return null;
  }
}
