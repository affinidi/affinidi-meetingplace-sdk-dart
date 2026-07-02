/// Tracks the (messageId, emoji, senderDid) tuple associated with each
/// incoming reaction event so a later redaction can locate and remove the
/// exact reaction — the one applied by that sender, not just any reaction
/// carrying the same emoji.
class IncomingReactionStateStore {
  final Map<String, ({String messageId, String emoji, String senderDid})>
  _eventIdToReaction = {};

  void register({
    required String eventId,
    required String messageId,
    required String reaction,
    required String senderDid,
  }) {
    _eventIdToReaction[eventId] = (
      messageId: messageId,
      emoji: reaction,
      senderDid: senderDid,
    );
  }

  ({String messageId, String emoji, String senderDid})? popByEventId(
    String eventId,
  ) {
    return _eventIdToReaction.remove(eventId);
  }
}
