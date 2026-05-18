import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('LivenessZkpAttachmentParser', () {
    test('tryParseProofIn returns payload for valid attachment', () {
      const payload = LivenessProofPayload(proof: 'abc', publicSignals: 'def');

      final attachments = [
        Attachment(
          id: '1',
          mediaType: 'application/json',
          format: LivenessZkpConstants.livenessProofFormat,
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
          format: LivenessZkpConstants.livenessCheckRequestFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(
            json: jsonEncode({
              LivenessZkpConstants.typeJsonKey:
                  LivenessZkpConstants.livenessRequestPayloadType,
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
          format: LivenessZkpConstants.livenessProofFormat,
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
          format: LivenessZkpConstants.livenessCheckRequestFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(
            json: jsonEncode(const LivenessCheckRequestPayload().toJson()),
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
        format: LivenessZkpConstants.livenessProofFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(
          json: jsonEncode(const LivenessCheckRequestPayload().toJson()),
        ),
      );
      final emptyPayload = Attachment(
        id: '2',
        mediaType: 'application/json',
        format: LivenessZkpConstants.livenessCheckRequestFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(json: '{}'),
      );
      final wrongType = Attachment(
        id: '3',
        mediaType: 'application/json',
        format: LivenessZkpConstants.livenessCheckRequestFormat,
        lastModifiedTime: DateTime.utc(2026),
        data: AttachmentData(
          json: jsonEncode({LivenessZkpConstants.typeJsonKey: 'other'}),
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
          format: LivenessZkpConstants.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: jsonEncode(payload.toJson())),
        ),
      ];
      final invalid = [
        Attachment(
          id: 'p',
          mediaType: 'application/json',
          format: LivenessZkpConstants.livenessProofFormat,
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
          LivenessZkpConstants.typeJsonKey: 'other',
        }),
        throwsA(isA<FormatException>()),
      );

      final payload = LivenessCheckRequestPayload.fromJson({
        LivenessZkpConstants.typeJsonKey:
            LivenessZkpConstants.livenessRequestPayloadType,
      });
      expect(payload, isA<LivenessCheckRequestPayload>());
    });
  });

  group('LivenessProofPayload.fromJson', () {
    test('rejects wrong type discriminator when present', () {
      expect(
        () => LivenessProofPayload.fromJson({
          LivenessZkpConstants.typeJsonKey: 'other',
          LivenessZkpConstants.proofJsonKey: 'a',
          LivenessZkpConstants.publicSignalsJsonKey: 'b',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('accepts missing type key for backward compatibility', () {
      final p = LivenessProofPayload.fromJson({
        LivenessZkpConstants.proofJsonKey: 'a',
        LivenessZkpConstants.publicSignalsJsonKey: 'b',
      });
      expect(p.proof, 'a');
      expect(p.publicSignals, 'b');
    });
  });
}
