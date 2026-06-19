import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import 'incoming_reaction_state_store.dart';
import 'target_message_resolver.dart';

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
       _reactionStateStore = reactionStateStore,
       _resolver = TargetMessageResolver(
         chatRepository: chatRepository,
         chatId: chatId,
         serverEventIdToMessageId: serverEventIdToMessageId,
       );

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final IncomingReactionStateStore _reactionStateStore;
  final TargetMessageResolver _resolver;

  Future<void> handle(MatrixRoomEvent event) async {
    final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
    final targetEventId = relatesTo?['event_id'] as String?;
    final reaction = relatesTo?['key'] as String?;
    final senderDid = event.senderDid;
    if (targetEventId == null || reaction == null || senderDid == null) return;

    final message = await _resolver.resolve(targetEventId);
    if (message == null) return;

    // The target message is tombstoned for the local user. The reaction
    // is dropped on the floor — we don't mutate, don't push to the stream,
    // and don't register it for later redaction matching (because there is
    // no local state to undo).
    if (message.isDeleted || message.isDeletedLocally) return;

    // Reactions are owned: the same emoji from two different participants is
    // two distinct reactions. Apply the change only when it is new, but always
    // remember the event id so a later redaction can undo it — including when
    // the reaction was already applied and is being replayed from history on
    // chat reopen (otherwise the redaction can't be matched and the reaction
    // would stick for everyone but its author).
    final owned = MessageReaction(emoji: reaction, senderDid: senderDid);
    if (!message.reactions.contains(owned)) {
      message.reactions.add(owned);
      await _chatRepository.updateMesssage(message);
      _chatStream.pushData(StreamData(chatItem: message));
    }
    _reactionStateStore.register(
      eventId: event.id,
      messageId: message.messageId,
      reaction: reaction,
      senderDid: senderDid,
    );
  }
}
