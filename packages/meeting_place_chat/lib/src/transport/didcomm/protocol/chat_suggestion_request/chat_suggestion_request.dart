import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_suggestion_request_body.dart';

/// [ChatSuggestionRequest] represents a DIDComm request for a suggestion,
/// anchored to an existing message id and its text context.
class ChatSuggestionRequest {
  factory ChatSuggestionRequest.create({
    required String from,
    required List<String> to,
    required String messageId,
    required String text,
  }) {
    return ChatSuggestionRequest(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatSuggestionRequestBody(messageId: messageId, text: text),
    );
  }

  factory ChatSuggestionRequest.fromPlainTextMessage(PlainTextMessage message) {
    return ChatSuggestionRequest(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatSuggestionRequestBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatSuggestionRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatSuggestionRequestBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.suggestionRequest.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
