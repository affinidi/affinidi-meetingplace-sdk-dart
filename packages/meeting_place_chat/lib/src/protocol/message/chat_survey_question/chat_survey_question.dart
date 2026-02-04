import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_survey_question_body.dart';

/// [ChatSurveyQuestion] represents a survey question message.
///
/// Answer options are expected to be provided as DIDComm attachments.
class ChatSurveyQuestion {
  factory ChatSurveyQuestion.create({
    required String question,
    required List<String> suggestions,
    required String from,
    required List<String> to,
    String? questionId,
  }) {
    final effectiveAttachments = <Attachment>[];

    final suggestionsJson = {'suggestions': suggestions};
    effectiveAttachments.add(
      Attachment(
        id: const Uuid().v4(),
        data: AttachmentData(json: jsonEncode(suggestionsJson)),
      ),
    );

    return ChatSurveyQuestion._(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatSurveyQuestionBody(question: question, questionId: questionId),
      attachments: effectiveAttachments,
    );
  }

  factory ChatSurveyQuestion.fromPlainTextMessage(PlainTextMessage message) {
    return ChatSurveyQuestion._(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatSurveyQuestionBody.fromJson(message.body ?? const {}),
      attachments: message.attachments ?? [],
      createdTime: message.createdTime,
    );
  }

  ChatSurveyQuestion._({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.attachments = const [],
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatSurveyQuestionBody body;
  final List<Attachment> attachments;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatQuestionWithAnswers.value),
      from: from,
      to: to,
      body: body.toJson(),
      attachments: attachments.isEmpty ? null : attachments,
      createdTime: createdTime,
    );
  }
}
