import 'dart:typed_data';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/w3c_eddsa_jcs_2022_vector.dart';

/// Multicodec prefix of an Ed25519 private key (`0x1300`, varint encoded).
const _ed25519PrivateKeyPrefixLength = 2;

Ed25519DidKeySigner _w3cSigner() {
  final privateKey = multiBaseToUint8List(w3cPrivateKeyMultibase);
  return Ed25519DidKeySigner.fromSeed(
    Uint8List.sublistView(privateKey, _ed25519PrivateKeyPrefixLength),
  );
}

Matcher _throwsInvalidProof() => throwsA(
  isA<MeetingPlaceVtcSDKException>().having(
    (error) => error.code,
    'code',
    MeetingPlaceVtcSDKErrorCode.invalidProof,
  ),
);

void main() {
  final resolver = UniversalDIDResolver.defaultResolver;

  group('EddsaJcs2022 with the W3C test vector', () {
    test('derives the vector verification method from the key', () {
      expect(_w3cSigner().verificationMethod, w3cVerificationMethod);
    });

    test('produces the vector proof value', () async {
      final signed = await EddsaJcs2022.sign(
        w3cUnsignedCredential(),
        signer: _w3cSigner(),
        purpose: ProofPurpose.assertionMethod,
        created: DateTime.parse(w3cCreated),
      );

      final proof = signed['proof'] as Map<String, dynamic>;
      expect(proof['proofValue'], w3cProofValue);
      expect(proof['created'], w3cCreated);
      expect(proof.containsKey('nonce'), isFalse);
    });

    test('verifies the vector document', () async {
      final signed = await EddsaJcs2022.sign(
        w3cUnsignedCredential(),
        signer: _w3cSigner(),
        purpose: ProofPurpose.assertionMethod,
        created: DateTime.parse(w3cCreated),
      );

      await expectLater(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.assertionMethod,
          resolver: resolver,
        ),
        completes,
      );
    });
  });

  group('EddsaJcs2022.verify', () {
    late Ed25519DidKeySigner signer;
    late Map<String, dynamic> signed;

    setUp(() async {
      signer = Ed25519DidKeySigner.generate();
      signed = await EddsaJcs2022.sign(
        {
          'issuer': signer.did,
          'payload': <String, dynamic>{'n': 1},
        },
        signer: signer,
        purpose: ProofPurpose.authentication,
      );
    });

    test('accepts an untouched document', () async {
      await expectLater(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.authentication,
          resolver: resolver,
          expectedSigner: signer.did,
        ),
        completes,
      );
    });

    test('rejects a tampered document', () {
      signed['payload'] = {'n': 2};
      expect(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.authentication,
          resolver: resolver,
        ),
        _throwsInvalidProof(),
      );
    });

    test('rejects a different purpose', () {
      expect(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.assertionMethod,
          resolver: resolver,
        ),
        _throwsInvalidProof(),
      );
    });

    test('rejects an unexpected signer', () {
      expect(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.authentication,
          resolver: resolver,
          expectedSigner: Ed25519DidKeySigner.generate().did,
        ),
        _throwsInvalidProof(),
      );
    });

    test('rejects a missing proof', () {
      signed.remove('proof');
      expect(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.authentication,
          resolver: resolver,
        ),
        _throwsInvalidProof(),
      );
    });

    test('rejects a proof by a key not in the signer DID document', () async {
      final other = Ed25519DidKeySigner.generate();
      final proof = Map<String, dynamic>.of(
        signed['proof'] as Map<String, dynamic>,
      )..['verificationMethod'] = '${signer.did}#${other.did.substring(8)}';
      signed['proof'] = proof;

      expect(
        EddsaJcs2022.verify(
          signed,
          purpose: ProofPurpose.authentication,
          resolver: resolver,
        ),
        _throwsInvalidProof(),
      );
    });
  });
}
