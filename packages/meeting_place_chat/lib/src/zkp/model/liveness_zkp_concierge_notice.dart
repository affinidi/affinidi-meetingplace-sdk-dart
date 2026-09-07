/// A pending human liveness ZKP concierge notice, prior to being mapped to a
/// `ConciergeMessage` for storage in the chat.
final class LivenessZkpConciergeNotice {
  /// Creates a [LivenessZkpConciergeNotice].
  const LivenessZkpConciergeNotice({
    required this.chatId,
    required this.messageId,
    required this.dateCreated,
    required this.conciergeType,
    required this.isFromMe,
    this.data = const {},
  });

  /// Unique identifier of the chat this notice belongs to.
  final String chatId;

  /// Unique identifier of the notice, derived via `LivenessZkpConciergeIds`.
  final String messageId;

  /// The timestamp indicating when the notice was created, in UTC.
  final DateTime dateCreated;

  /// One of the `LivenessZkpConciergeTypes` values identifying the notice
  /// kind.
  final String conciergeType;

  /// Whether the notice represents an action taken by the current user.
  final bool isFromMe;

  /// Additional structured metadata for the notice (e.g. `contactName`).
  final Map<String, Object?> data;
}
