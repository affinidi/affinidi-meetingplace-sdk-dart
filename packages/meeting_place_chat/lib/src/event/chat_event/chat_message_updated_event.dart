part of 'chat_event.dart';

/// An existing chat message was updated in place.
///
/// The updated message content is available on `StreamData.chatItem`.
/// Consumers that maintain a local message list should replace the existing
/// entry with the same `messageId` rather than appending a new item.
final class ChatMessageUpdatedEvent extends ChatEvent {
  const ChatMessageUpdatedEvent();
}
