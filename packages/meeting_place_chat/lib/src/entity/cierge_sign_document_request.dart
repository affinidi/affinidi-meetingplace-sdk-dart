import 'dart:convert';

/// Parsed payload for a `cierge/sign-document-request` message.
///
/// Use [fromMessageText] to attempt parsing; returns `null`
/// for non-matching input.
class CiergeSignDocumentRequest {
  const CiergeSignDocumentRequest({required this.document, this.taskId});

  static const String messageType = 'cierge/sign-document-request';

  static const String conciergeTypeName = 'signDocumentRequest';

  final Map<String, dynamic> document;
  final String? taskId;

  String? get title => document['title'] as String?;
  String? get content => document['content'] as String?;

  static CiergeSignDocumentRequest? fromMessageText(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['type'] != messageType) return null;
      final document = decoded['document'] as Map<String, dynamic>? ?? {};
      return CiergeSignDocumentRequest(
        document: document,
        taskId: decoded['taskId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
