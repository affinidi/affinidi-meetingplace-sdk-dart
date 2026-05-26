part of 'chat_event.dart';

/// A typing/activity indicator was received.
final class ChatActivityEvent extends ChatEvent {
  const ChatActivityEvent({
    required this.senderDid,
    required this.timestamp,
    required this.createdTime,
  });

  /// DID of the sender, used for group typing indicators.
  final String senderDid;

  /// Timestamp from the activity body.
  final DateTime timestamp;

  /// When the activity message was created.
  final DateTime? createdTime;
}
