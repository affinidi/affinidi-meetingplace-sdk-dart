/// A transport-agnostic event received on the chat stream.
///
/// [ChatEvent] replaces the DIDComm-specific `PlainTextMessage` type on the
/// public SDK boundary. The SDK converts incoming `PlainTextMessage` values to
/// [ChatEvent] internally before pushing them onto the stream.
class ChatEvent {
  ChatEvent({required this.type, this.senderDid, this.body, this.createdTime});

  /// Protocol message type URI as a string.
  ///
  /// Matches values from `ChatProtocol`
  /// (e.g. `ChatProtocol.chatMessage.value`).
  final String type;

  /// DID of the sender, if present.
  final String? senderDid;

  /// Protocol-specific body payload.
  final Map<String, dynamic>? body;

  /// Timestamp when the event was created, if present.
  final DateTime? createdTime;
}
