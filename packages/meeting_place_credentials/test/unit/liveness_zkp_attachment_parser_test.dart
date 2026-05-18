import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('LivenessZkpAttachmentParser', () {
    test(
      'tryParseLivenessProofPayload returns payload for valid attachment',
      () {
        const payload = LivenessProofPayload(
          proof: 'abc',
          publicSignals: 'def',
        );

        final attachments = [
          Attachment(
            id: '1',
            mediaType: 'application/json',
            format: LivenessZkpConstants.livenessProofFormat,
            lastModifiedTime: DateTime.utc(2026),
            data: AttachmentData(json: jsonEncode(payload.toJson())),
          ),
        ];

        final parsed = LivenessZkpAttachmentParser.tryParseLivenessProofPayload(
          attachments,
        );

        expect(parsed, isNotNull);
        expect(parsed!.proof, 'abc');
        expect(parsed.publicSignals, 'def');
      },
    );

    test('tryParseLivenessProofPayload skips wrong format', () {
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

      expect(
        LivenessZkpAttachmentParser.tryParseLivenessProofPayload(attachments),
        isNull,
      );
    });

    test('tryParseLivenessProofPayload returns null on invalid JSON', () {
      final attachments = [
        Attachment(
          id: '1',
          mediaType: 'application/json',
          format: LivenessZkpConstants.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: 'not-json'),
        ),
      ];

      expect(
        LivenessZkpAttachmentParser.tryParseLivenessProofPayload(attachments),
        isNull,
      );
    });

    test('hasLivenessCheckRequest / hasLivenessProof', () {
      final attachments = [
        Attachment(
          id: 'r',
          mediaType: 'application/json',
          format: LivenessZkpConstants.livenessCheckRequestFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: '{}'),
        ),
        Attachment(
          id: 'p',
          mediaType: 'application/json',
          format: LivenessZkpConstants.livenessProofFormat,
          lastModifiedTime: DateTime.utc(2026),
          data: AttachmentData(json: '{}'),
        ),
      ];

      expect(
        LivenessZkpAttachmentParser.hasLivenessCheckRequest(attachments),
        isTrue,
      );
      expect(LivenessZkpAttachmentParser.hasLivenessProof(attachments), isTrue);
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
