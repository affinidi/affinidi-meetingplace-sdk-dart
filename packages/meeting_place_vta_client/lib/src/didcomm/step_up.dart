import 'dart:convert';

class VtaDidCommStepUp {
  static const String approveRequestType =
      'https://trusttasks.org/spec/auth/step-up/approve-request/0.1';

  static Map<String, dynamic>? extractBodyDocument(String messageJson) {
    final root = _decodeObject(messageJson);
    if (root == null) {
      return null;
    }

    final body = root['body'];
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return body.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static bool isApproveRequestDocument(Map<String, dynamic> document) {
    return document['type'] == approveRequestType;
  }

  static Map<String, dynamic>? extractApproveRequest(String messageJson) {
    final body = extractBodyDocument(messageJson);
    if (body == null) {
      return null;
    }
    return isApproveRequestDocument(body) ? body : null;
  }

  static Map<String, dynamic>? extractApproveRequestFromMessage(
    Map<String, dynamic> didcommMessage,
  ) {
    final body = didcommMessage['body'];
    if (body is Map<String, dynamic>) {
      return isApproveRequestDocument(body) ? body : null;
    }
    if (body is Map) {
      final normalized = body.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return isApproveRequestDocument(normalized) ? normalized : null;
    }
    return null;
  }

  static Map<String, dynamic>? _decodeObject(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
