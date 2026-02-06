import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import 'chat_survey_question_body.dart';

/// [ChatSurveyQuestion] represents a survey question message.
///
/// Answer options are expected to be provided as DIDComm attachments.
class ChatSurveyQuestion {
  factory ChatSurveyQuestion.create({
    required String from,
    required List<String> to,
    required String question,
    required int seqNo,
    required List<String> suggestions,
    required String messageId,
    bool isAnswered = false,
  }) {
    return ChatSurveyQuestion._(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatSurveyQuestionBody(
        question: question,
        questionId: messageId,
        suggestions: suggestions,
        seqNo: seqNo,
        isAnswered: isAnswered,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  factory ChatSurveyQuestion.fromPlainTextMessage(PlainTextMessage message) {
    return ChatSurveyQuestion._(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatSurveyQuestionBody.fromJson(message.body ?? const {}),
      createdTime:
          DateTime.tryParse(message.body?['timestamp'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  ChatSurveyQuestion._({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatSurveyQuestionBody body;
  final DateTime createdTime;

  static const String type =
      'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/survey-question';

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatSurveyQuestion.type),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }

  List<String> get suggestions => body.suggestions;
  int get seqNo => body.seqNo;
  String get question => body.question;
  bool get isAnswered => body.isAnswered;

  Map<String, dynamic> get data => {
    'suggestions': suggestions,
    'isAnswered': isAnswered,
    'type': 'question',
  };
}
