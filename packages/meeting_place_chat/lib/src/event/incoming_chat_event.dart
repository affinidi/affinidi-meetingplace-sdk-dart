/// Transport-neutral representation of an incoming chat event delivered to
/// chat-level handlers. Transport adapters (e.g., Matrix) translate
/// transport-specific events into this shape before dispatch.
class IncomingChatEvent {
  IncomingChatEvent({
    required this.type,
    required this.senderDid,
    required this.content,
    this.targetDid,
  });

  /// Transport-neutral event type identifier used for dispatch.
  final String type;

  /// DID of the sender, resolved by the transport adapter. `null` if the
  /// transport could not resolve the sender's identity.
  final String? senderDid;

  /// Event payload.
  final Map<String, dynamic> content;

  /// DID of the user this event affects, when distinct from [senderDid].
  /// Resolved by the transport router using context only it has (e.g. the
  /// group's member list). For membership changes initiated by another party
  /// (e.g. an owner kicking a member), this is the affected user.
  final String? targetDid;
}
