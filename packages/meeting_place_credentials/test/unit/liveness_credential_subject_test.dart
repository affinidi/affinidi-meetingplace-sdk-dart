import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:test/test.dart';

void main() {
  group('LivenessCredentialSubject', () {
    test('maps evidence fields to credentialSubject JSON', () {
      final evidence = LivenessEvidence(
        providerId: 'azure_face_liveness',
        providerTransactionId: 'session-123',
        livenessScore: 92.5,
        livenessThreshold: 80,
        checkedAt: DateTime.utc(2026, 5, 29, 12),
      );

      final subject = LivenessCredentialSubject(
        holderDid: 'did:example:holder',
        evidence: evidence,
      );

      expect(subject.toJson(), {
        'id': 'did:example:holder',
        'livenessProvider': 'azure_face_liveness',
        'livenessSessionId': 'session-123',
        'livenessScore': 92.5,
        'livenessThreshold': 80.0,
        'livenessPassed': true,
        'checkedAt': '2026-05-29T12:00:00.000Z',
      });
    });
  });

  group('LivenessEvidence', () {
    test('isLive compares score against threshold', () {
      final passed = LivenessEvidence(
        providerId: 'demo',
        providerTransactionId: 'tx-1',
        livenessScore: 80,
        livenessThreshold: 80,
        checkedAt: _checkedAt,
      );
      final failed = LivenessEvidence(
        providerId: 'demo',
        providerTransactionId: 'tx-2',
        livenessScore: 79.9,
        livenessThreshold: 80,
        checkedAt: _checkedAt,
      );

      expect(passed.isLive, isTrue);
      expect(failed.isLive, isFalse);
    });
  });
}

final _checkedAt = DateTime.utc(2026, 1, 1);
