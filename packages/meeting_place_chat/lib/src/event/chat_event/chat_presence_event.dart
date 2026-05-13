part of 'chat_event.dart';

/// A presence signal was received (online/offline indicator).
final class ChatPresenceEvent extends ChatEvent {
  const ChatPresenceEvent({required this.timestamp});

  /// When the presence signal was created.
  final DateTime timestamp;
}
