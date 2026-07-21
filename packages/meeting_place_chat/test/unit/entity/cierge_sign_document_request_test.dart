import 'dart:convert';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('CiergeSignDocumentRequest.fromMessageText', () {
    test('parses valid sign-document-request', () {
      final text = jsonEncode({
        'type': 'cierge/sign-document-request',
        'document': {'title': 'Test Contract', 'content': 'aGVsbG8='},
      });
      final result = CiergeSignDocumentRequest.fromMessageText(text);
      expect(result, isNotNull);
      expect(result!.title, 'Test Contract');
      expect(result.content, 'aGVsbG8=');
    });

    test('parses request with taskId', () {
      final text = jsonEncode({
        'type': 'cierge/sign-document-request',
        'document': {'title': 'NDA'},
        'taskId': 'task-123',
      });
      final result = CiergeSignDocumentRequest.fromMessageText(text);
      expect(result, isNotNull);
      expect(result!.taskId, 'task-123');
    });

    test('parses request without document field', () {
      final text = jsonEncode({'type': 'cierge/sign-document-request'});
      final result = CiergeSignDocumentRequest.fromMessageText(text);
      expect(result, isNotNull);
      expect(result!.document, isEmpty);
    });

    test('returns null for regular text', () {
      expect(CiergeSignDocumentRequest.fromMessageText('hello'), isNull);
    });

    test('returns null for empty string', () {
      expect(CiergeSignDocumentRequest.fromMessageText(''), isNull);
    });

    test('returns null for JSON without type field', () {
      final text = jsonEncode({'document': {'title': 'Test'}});
      expect(CiergeSignDocumentRequest.fromMessageText(text), isNull);
    });

    test('returns null for wrong type', () {
      final text = jsonEncode({'type': 'cierge/other-request'});
      expect(CiergeSignDocumentRequest.fromMessageText(text), isNull);
    });

    test('returns null for signature payload', () {
      final text = jsonEncode({
        'messageId': 'abc',
        'signerDid': 'did:key:z...',
        'signature': 'z...',
      });
      expect(CiergeSignDocumentRequest.fromMessageText(text), isNull);
    });

    test('returns null for JSON array', () {
      expect(CiergeSignDocumentRequest.fromMessageText('[1,2,3]'), isNull);
    });

    test('returns null for malformed JSON', () {
      expect(CiergeSignDocumentRequest.fromMessageText('{not json'), isNull);
    });

    test('returns null for sign-consent-granted type', () {
      final text = jsonEncode({
        'type': 'cierge/sign-consent-granted',
        'taskId': 'abc-123',
      });
      expect(CiergeSignDocumentRequest.fromMessageText(text), isNull);
    });
  });

  group('CiergeSignDocumentRequest constants', () {
    test('messageType matches expected value', () {
      expect(
        CiergeSignDocumentRequest.messageType,
        'cierge/sign-document-request',
      );
    });

    test('conciergeTypeName matches expected value', () {
      expect(
        CiergeSignDocumentRequest.conciergeTypeName,
        'signDocumentRequest',
      );
    });
  });
}
