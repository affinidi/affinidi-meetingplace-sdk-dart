/// Transport-neutral representation of an incoming chat event delivered to
/// chat-level handlers. Transport adapters (e.g., Matrix) translate
/// transport-specific events into this shape before dispatch.
class IncomingChatEvent {
  IncomingChatEvent({
    required this.type,
    required this.senderDid,
    required this.content,
  });

  /// Transport-neutral event type identifier used for dispatch.
  final String type;

  /// DID of the sender, resolved by the transport adapter. `null` if the
  /// transport could not resolve the sender's identity.
  final String? senderDid;

  /// Event payload.
  final Map<String, dynamic> content;
}
