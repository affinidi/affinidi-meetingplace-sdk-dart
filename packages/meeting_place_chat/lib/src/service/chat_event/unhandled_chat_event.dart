part of 'chat_event.dart';

/// An event type not handled by the SDK was received.
///
/// Inspect [type] to identify the protocol and [body] for raw payload access.
final class UnhandledChatEvent extends ChatEvent {
  const UnhandledChatEvent({
    required this.type,
    this.senderDid,
    this.body,
    this.createdTime,
  });

  /// Protocol message type URI.
  final String type;

  /// DID of the sender, if present.
  final String? senderDid;

  /// Raw protocol body payload.
  final Map<String, dynamic>? body;

  /// Timestamp when the event was created, if present.
  final DateTime? createdTime;
}
