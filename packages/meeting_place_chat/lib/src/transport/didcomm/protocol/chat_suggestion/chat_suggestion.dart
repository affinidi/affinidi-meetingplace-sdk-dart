import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_suggestion_body.dart';

/// [ChatSuggestion] represents a DIDComm suggestion message anchored to an
/// existing message id and its text context.
class ChatSuggestion {
  factory ChatSuggestion.create({
    required String from,
    required List<String> to,
    required String relatedMessageId,
    required String text,
  }) {
    return ChatSuggestion(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatSuggestionBody(
        relatedMessageId: relatedMessageId,
        text: text,
      ),
    );
  }

  factory ChatSuggestion.fromPlainTextMessage(PlainTextMessage message) {
    return ChatSuggestion(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatSuggestionBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatSuggestion({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatSuggestionBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.suggestion.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}