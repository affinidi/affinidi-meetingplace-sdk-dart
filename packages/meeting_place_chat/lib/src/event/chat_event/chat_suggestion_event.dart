part of 'chat_event.dart';

/// A suggestion event was received from the remote party or personal agent.
final class ChatSuggestionEvent extends ChatEvent {
  const ChatSuggestionEvent({
    this.senderDid,
    required this.relatedMessageId,
    required this.text,
    required this.createdTime,
  });

  /// DID of the sender, if present.
  final String? senderDid;

  /// Local chat message id this suggestion is anchored to.
  final String relatedMessageId;

  /// Suggested text content.
  final String text;

  /// Timestamp when the suggestion was created.
  final DateTime createdTime;
}
