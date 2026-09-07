part of 'chat_event.dart';

/// One or more previously sent messages were acknowledged as delivered by
/// the recipient. [messageIds] lists the affected message ids.
final class ChatMessageDeliveredEvent extends ChatEvent {
  const ChatMessageDeliveredEvent({required this.messageIds});

  /// Ids of the messages that were acknowledged as delivered.
  final List<String> messageIds;
}
