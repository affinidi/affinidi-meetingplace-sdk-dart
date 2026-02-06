import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

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
    return ChatSurveyResponse(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatSurveyResponseBody.fromJson(message.body ?? const {}),
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

  static const String type =
      'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/survey-response';

  final String id;
  final String from;
  final List<String> to;
  final ChatSurveyResponseBody body;
  final DateTime createdTime;
  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatSurveyResponse.type),
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
