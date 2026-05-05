part of 'chat_event.dart';

/// A chat message was received or sent.
///
/// The message content is available on `StreamData.chatItem`.
final class ChatMessageEvent extends ChatEvent {
  const ChatMessageEvent();
}
