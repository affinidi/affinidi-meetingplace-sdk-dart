import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:test/test.dart';

const _testChallengeNonceHex =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';

LivenessCheckRequestPayload _testRequestPayload() =>
    LivenessCheckRequestPayload(challengeNonceHex: _testChallengeNonceHex);

void main() {
  group('LivenessZkpAttachmentParser', () {
    test('matchesRequestFormat and matchesProofFormat are format only', () {
      final requestFormatOnly = Attachment(
        id: 'r',
        mediaType: 'application/json',
        format: LivenessZkpProtocol.livenessCheckRequestFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(json: '{}'),
      );
      final proofFormatOnly = Attachment(
        id: 'p',
        mediaType: 'application/json',
        format: LivenessZkpProtocol.livenessProofFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(json: '{}'),
      );

      expect(
        LivenessZkpAttachmentParser.matchesRequestFormat(requestFormatOnly),
        isTrue,
      );
      expect(
        LivenessZkpAttachmentParser.matchesProofFormat(proofFormatOnly),
        isTrue,
      );
      expect(LivenessZkpAttachmentParser.isRequest(requestFormatOnly), isFalse);
      expect(LivenessZkpAttachmentParser.isProof(proofFormatOnly), isFalse);
    });

    test('tryParseProofIn returns payload for valid attachment', () {
      const payload = LivenessProofPayload(proof: 'abc', publicSignals: 'def');

      final attachments = [
        Attachment(
          id: '1',
          mediaType: 'application/json',
          format: LivenessZkpProtocol.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: jsonEncode(payload.toJson())),
        ),
      ];

      final parsed = LivenessZkpAttachmentParser.tryParseProofIn(attachments);

      expect(parsed, isNotNull);
      expect(parsed!.proof, 'abc');
      expect(parsed.publicSignals, 'def');
    });

    test('tryParseProofIn skips wrong format', () {
      final attachments = [
        Attachment(
          id: '1',
          mediaType: 'application/json',
          format: LivenessZkpProtocol.livenessCheckRequestFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(
            json: jsonEncode({
              LivenessZkpProtocol.typeJsonKey:
                  LivenessZkpProtocol.livenessRequestPayloadType,
            }),
          ),
        ),
      ];

      expect(LivenessZkpAttachmentParser.tryParseProofIn(attachments), isNull);
    });

    test('tryParseProofIn returns null on invalid JSON', () {
      final attachments = [
        Attachment(
          id: '1',
          mediaType: 'application/json',
          format: LivenessZkpProtocol.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: 'not-json'),
        ),
      ];

      expect(LivenessZkpAttachmentParser.tryParseProofIn(attachments), isNull);
    });

    test('tryParseRequest returns payload for valid attachment', () {
      final attachments = [
        Attachment(
          id: 'r',
          mediaType: 'application/json',
          format: LivenessZkpProtocol.livenessCheckRequestFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(
            json: jsonEncode(_testRequestPayload().toJson()),
          ),
        ),
      ];

      expect(
        LivenessZkpAttachmentParser.tryParseRequest(attachments.single),
        isNotNull,
      );
      expect(
        LivenessZkpAttachmentParser.tryParseRequestIn(attachments),
        isNotNull,
      );
      expect(LivenessZkpAttachmentParser.isRequest(attachments.single), isTrue);
      expect(LivenessZkpAttachmentParser.hasRequest(attachments), isTrue);
    });

    test('tryParseRequest rejects wrong format or payload', () {
      final wrongFormat = Attachment(
        id: '1',
        mediaType: 'application/json',
        format: LivenessZkpProtocol.livenessProofFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(json: jsonEncode(_testRequestPayload().toJson())),
      );
      final emptyPayload = Attachment(
        id: '2',
        mediaType: 'application/json',
        format: LivenessZkpProtocol.livenessCheckRequestFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(json: '{}'),
      );
      final wrongType = Attachment(
        id: '3',
        mediaType: 'application/json',
        format: LivenessZkpProtocol.livenessCheckRequestFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(
          json: jsonEncode({LivenessZkpProtocol.typeJsonKey: 'other'}),
        ),
      );

      for (final attachment in [wrongFormat, emptyPayload, wrongType]) {
        expect(LivenessZkpAttachmentParser.tryParseRequest(attachment), isNull);
        expect(LivenessZkpAttachmentParser.isRequest(attachment), isFalse);
      }
      expect(
        LivenessZkpAttachmentParser.hasRequest([emptyPayload, wrongType]),
        isFalse,
      );
    });

    test('hasProof requires valid proof payload', () {
      const payload = LivenessProofPayload(proof: 'a', publicSignals: 'b');
      final valid = [
        Attachment(
          id: 'p',
          mediaType: 'application/json',
          format: LivenessZkpProtocol.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: jsonEncode(payload.toJson())),
        ),
      ];
      final invalid = [
        Attachment(
          id: 'p',
          mediaType: 'application/json',
          format: LivenessZkpProtocol.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: '{}'),
        ),
      ];

      expect(LivenessZkpAttachmentParser.hasProof(valid), isTrue);
      expect(LivenessZkpAttachmentParser.hasProof(invalid), isFalse);
    });
  });

  group('LivenessCheckRequestPayload.fromJson', () {
    test('requires liveness_request type', () {
      expect(
        () => LivenessCheckRequestPayload.fromJson({}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => LivenessCheckRequestPayload.fromJson({
          LivenessZkpProtocol.typeJsonKey: 'other',
        }),
        throwsA(isA<FormatException>()),
      );

      final payload = LivenessCheckRequestPayload.fromJson({
        LivenessZkpProtocol.typeJsonKey:
            LivenessZkpProtocol.livenessRequestPayloadType,
        LivenessZkpProtocol.challengeNonceJsonKey: _testChallengeNonceHex,
      });
      expect(payload, isA<LivenessCheckRequestPayload>());
      expect(payload.challengeNonceBytes, hasLength(32));
    });
  });

  group('LivenessProofPayload.fromJson', () {
    test('requires liveness_proof type', () {
      expect(
        () => LivenessProofPayload.fromJson({
          LivenessZkpProtocol.proofJsonKey: 'a',
          LivenessZkpProtocol.publicSignalsJsonKey: 'b',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => LivenessProofPayload.fromJson({
          LivenessZkpProtocol.typeJsonKey: 'other',
          LivenessZkpProtocol.proofJsonKey: 'a',
          LivenessZkpProtocol.publicSignalsJsonKey: 'b',
        }),
        throwsA(isA<FormatException>()),
      );

      final p = LivenessProofPayload.fromJson({
        LivenessZkpProtocol.typeJsonKey:
            LivenessZkpProtocol.livenessProofPayloadType,
        LivenessZkpProtocol.proofJsonKey: 'a',
        LivenessZkpProtocol.publicSignalsJsonKey: 'b',
      });
      expect(p.proof, 'a');
      expect(p.publicSignals, 'b');
    });
  });
}
