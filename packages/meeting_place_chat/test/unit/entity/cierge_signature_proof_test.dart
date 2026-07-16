import 'dart:convert';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('CiergeSignatureProof.fromAttachment', () {
    test('parses a valid cierge/signature payload', () {
      final attachment = ChatAttachment(
        id: 'sig-1',
        mediaType: 'application/json',
        format: CiergeSignatureProof.attachmentFormat,
        data: ChatAttachmentData(
          json:
              '{"messageId":"urn:uuid:1","signerDid":"did:key:zabc",'
              '"timestamp":"2026-07-14T13:23:31.000Z","tokenId":"tok-1",'
              '"signature":"abc","context":"ctx-a",'
              '"memory":"local-file","model":"gpt-4o"}',
        ),
      );

      final parsed = CiergeSignatureProof.fromAttachment(attachment);

      expect(parsed, isNotNull);
      expect(parsed!.signature, 'abc');
      expect(parsed.context, 'ctx-a');
      expect(parsed.memory, 'local-file');
      expect(parsed.model, 'gpt-4o');
    });

    test('returns null for non-signature format', () {
      final attachment = ChatAttachment(
        id: 'other',
        format: 'application/custom',
        data: ChatAttachmentData(json: '{"signature":"abc"}'),
      );

      expect(CiergeSignatureProof.fromAttachment(attachment), isNull);
    });

    test('returns null when signature field is missing', () {
      final attachment = ChatAttachment(
        id: 'sig-2',
        format: CiergeSignatureProof.attachmentFormat,
        data: ChatAttachmentData(json: '{"context":"ctx-a"}'),
      );

      expect(CiergeSignatureProof.fromAttachment(attachment), isNull);
    });

    test('parses payload from base64 when json field is absent', () {
      final raw = '{"signature":"abc","context":"ctx-a","memory":"local-file"}';
      final attachment = ChatAttachment(
        id: 'sig-3',
        format: CiergeSignatureProof.attachmentFormat,
        data: ChatAttachmentData(base64: base64Encode(utf8.encode(raw))),
      );

      final parsed = CiergeSignatureProof.fromAttachment(attachment);

      expect(parsed, isNotNull);
      expect(parsed!.signature, 'abc');
      expect(parsed.context, 'ctx-a');
      expect(parsed.memory, 'local-file');
    });

    test('returns null for malformed inline json payload', () {
      final attachment = ChatAttachment(
        id: 'sig-4',
        format: CiergeSignatureProof.attachmentFormat,
        data: ChatAttachmentData(json: '{"signature":"abc"'),
      );

      expect(CiergeSignatureProof.fromAttachment(attachment), isNull);
    });

    test('returns null for malformed base64-decoded json payload', () {
      final attachment = ChatAttachment(
        id: 'sig-5',
        format: CiergeSignatureProof.attachmentFormat,
        data: ChatAttachmentData(
          base64: base64Encode(utf8.encode('{bad json')),
        ),
      );

      expect(CiergeSignatureProof.fromAttachment(attachment), isNull);
    });

    test('returns null for invalid base64 payload', () {
      final attachment = ChatAttachment(
        id: 'sig-6',
        format: CiergeSignatureProof.attachmentFormat,
        data: ChatAttachmentData(base64: 'not-base64%%%'),
      );

      expect(CiergeSignatureProof.fromAttachment(attachment), isNull);
    });
  });
}
