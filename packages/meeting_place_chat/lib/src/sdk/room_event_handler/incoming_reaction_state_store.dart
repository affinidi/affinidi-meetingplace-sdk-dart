/// Tracks the (messageId, reaction) tuple associated with each incoming
/// reaction event so a later redaction can locate and remove it.
class IncomingReactionStateStore {
  final Map<String, String> _eventIdToReactionKey = {};

  void register({
    required String eventId,
    required String messageId,
    required String reaction,
  }) {
    _eventIdToReactionKey[eventId] = '$messageId:$reaction';
  }

  ({String messageId, String reaction})? popByEventId(String eventId) {
    final entry = _eventIdToReactionKey.remove(eventId);
    if (entry == null) return null;
    final separatorIndex = entry.lastIndexOf(':');
    if (separatorIndex == -1) return null;
    return (
      messageId: entry.substring(0, separatorIndex),
      reaction: entry.substring(separatorIndex + 1),
    );
  }
}
