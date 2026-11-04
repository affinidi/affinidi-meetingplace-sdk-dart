import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_vtc.dart';

void main() {
  group('TrustTaskExchange', () {
    late TrustTaskDocument request;
    late TrustTaskDocument answer;

    setUp(() async {
      final agent = FakeSignInAgent();
      request = await TrustTaskDocument.create(
        type: JoinTask.submit,
        issuer: agent.persona.did,
        recipient: vtcDid,
        payload: const {'criterion': 'z1'},
      ).sign(agent.persona, purpose: ProofPurpose.authentication);
      answer = await TrustTaskDocument.create(
        type: '${JoinTask.submit}#response',
        issuer: vtcDid,
        recipient: agent.persona.did,
        threadId: request.id,
        payload: const {'requestId': 'request-1'},
      ).sign(communitySigner(), purpose: ProofPurpose.authentication);
    });

    test('restores both documents exactly as they were', () {
      final exchange = TrustTaskExchange(request: request, answer: answer);

      final restored = TrustTaskExchange.fromJson(exchange.toJson());

      expect(restored.request.toJson(), request.toJson());
      expect(restored.answer.toJson(), answer.toJson());
      expect(restored.receipt.toJson(), exchange.receipt.toJson());
    });
  });

  group('TrustTaskReceipt', () {
    late TrustTaskDocument request;
    late TrustTaskDocument answer;

    setUp(() async {
      final agent = FakeSignInAgent();
      request = await TrustTaskDocument.create(
        type: JoinTask.submit,
        issuer: agent.persona.did,
        recipient: vtcDid,
        payload: {
          'attributes': [
            {'type': 'name', 'value': 'Alice'},
          ],
        },
        issuedAt: DateTime.utc(2026, 11, 4, 10, 12),
      ).sign(agent.persona, purpose: ProofPurpose.authentication);
      answer = await TrustTaskDocument.create(
        type: '${JoinTask.submit}#response',
        issuer: vtcDid,
        recipient: agent.persona.did,
        threadId: request.id,
        payload: const {'requestId': 'request-1'},
        issuedAt: DateTime.utc(2026, 11, 4, 10, 13),
      ).sign(communitySigner(), purpose: ProofPurpose.authentication);
    });

    test('reads the request, its proof and who answered', () {
      final receipt = TrustTaskReceipt.exchange(request, answer);

      expect(receipt.type, JoinTask.submit);
      expect(receipt.documentId, request.id);
      expect(receipt.signer, request.issuer);
      expect(receipt.cryptosuite, 'eddsa-jcs-2022');
      expect(
        receipt.verificationMethod,
        (request.toJson()['proof'] as Map)['verificationMethod'],
      );
      expect(receipt.signedAt, isNotNull);
      expect(receipt.proofPurpose, 'authentication');
      expect(receipt.answeredBy, vtcDid);
      expect(receipt.answerType, '${JoinTask.submit}#response');
      expect(receipt.answerDocumentId, answer.id);
      expect(receipt.answeredAt, DateTime.utc(2026, 11, 4, 10, 13));
    });

    test("reads the answer's proof", () {
      final receipt = TrustTaskReceipt.exchange(request, answer);
      final proof = answer.toJson()['proof'] as Map;

      expect(receipt.answerCryptosuite, 'eddsa-jcs-2022');
      expect(receipt.answerVerificationMethod, proof['verificationMethod']);
      expect(receipt.answerVerificationMethod, startsWith('$vtcDid#'));
      expect(receipt.answerProofPurpose, 'authentication');
      expect(
        receipt.answerSignedAt,
        DateTime.parse(proof['created'] as String),
      );
    });

    test('keeps no payload or signature', () {
      final json = TrustTaskReceipt.exchange(request, answer).toJson();

      expect(json.toString(), isNot(contains('Alice')));
      expect(json.toString(), isNot(contains('proofValue')));
    });

    test('restores what it stored', () {
      final receipt = TrustTaskReceipt.exchange(request, answer);
      final restored = TrustTaskReceipt.fromJson(receipt.toJson());

      expect(restored.toJson(), receipt.toJson());
      expect(restored.signedAt, receipt.signedAt);
      expect(restored.answeredAt, receipt.answeredAt);
      expect(restored.answerSignedAt, receipt.answerSignedAt);
    });

    test("restores a receipt stored without the answer's proof", () {
      final json = TrustTaskReceipt.exchange(request, answer).toJson()
        ..removeWhere(
          (key, _) =>
              key.startsWith('answer') && key != 'answeredBy' ||
              key == 'proofPurpose',
        );

      final restored = TrustTaskReceipt.fromJson(json);

      expect(restored.answeredBy, vtcDid);
      expect(restored.answerCryptosuite, isNull);
      expect(restored.answerVerificationMethod, isNull);
      expect(restored.answerSignedAt, isNull);
      expect(restored.proofPurpose, isNull);
    });
  });
}
