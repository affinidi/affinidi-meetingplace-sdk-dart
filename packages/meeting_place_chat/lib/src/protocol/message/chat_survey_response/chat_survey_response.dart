import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../protocol.dart';
import 'chat_survey_response_body.dart';

/// [ChatSurveyResponse] represents an answer to a [ChatSurveyQuestion].
class ChatSurveyResponse {
  factory ChatSurveyResponse.create({
    required String text,
    required String from,
    required List<String> to,
    required int seqNo,
    required String parentMessageId,
  }) {
    return ChatSurveyResponse(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatSurveyResponseBody(
        text: text,
        seqNo: seqNo,
        parentMessageId: parentMessageId,
      ),
    );
  }

  factory ChatSurveyResponse.fromPlainTextMessage(PlainTextMessage message) {
    final messageBody = message.body;

    if (messageBody == null) {
      throw ArgumentError(
        'Message body is required to create ChatSurveyResponse',
      );
    }
    return ChatSurveyResponse(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatSurveyResponseBody.fromJson(messageBody),
      createdTime: message.createdTime,
    );
  }

  ChatSurveyResponse({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatSurveyResponseBody body;
  final DateTime createdTime;
  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatSurveyResponse.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }

  Map<String, dynamic> get data => {
    'parent_message_id': body.parentMessageId,
    'type': 'response',
  };
}
