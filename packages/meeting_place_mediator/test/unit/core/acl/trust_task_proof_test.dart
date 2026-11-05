import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/src/core/acl/trust_task_proof.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

void main() {
  const mediatorDid = 'did:example:mediator';
  final created = DateTime.utc(2026, 11, 5, 13, 40, 12, 345);

  TrustTaskDocument task(String issuer) => TrustTaskDocument(
    type: AccessListUpdateTask.taskType,
    issuer: issuer,
    recipient: mediatorDid,
    issuedAt: DateTime.utc(2026, 11, 5, 13, 40, 11, 999),
    payload: const {
      'did': 'did:example:owner',
      'add': ['did:example:grantee'],
    },
  );

  DidSigner signerOf(KeyPair keyPair, SignatureScheme scheme) {
    final did = 'did:key:${keyPair.publicKey.type.name}';
    return DidSigner(
      did: did,
      didKeyId: '$did#key-1',
      keyPair: keyPair,
      signatureScheme: scheme,
    );
  }

  test('signs a task with eddsa-jcs-2022 as the issuer', () async {
    final (keyPair, _) = Ed25519KeyPair.generate();
    final signer = signerOf(keyPair, SignatureScheme.ed25519);
    final unsigned = task(signer.did);

    final signed = await TrustTaskProof.sign(
      unsigned,
      signer: signer,
      created: created,
    );

    expect(signed.toJson()..remove('proof'), unsigned.toJson());
    final proof = Map<String, dynamic>.of(signed.proof!);
    final proofValue = proof.remove('proofValue') as String;
    expect(proof, {
      'type': 'DataIntegrityProof',
      'cryptosuite': 'eddsa-jcs-2022',
      'created': '2026-11-05T13:40:12Z',
      'verificationMethod': signer.didKeyId,
      'proofPurpose': 'authentication',
    });
    expect(proofValue, startsWith('z'));
    expect(
      await keyPair.verify(
        TrustTaskProof.hashData(proof, unsigned.toJson()),
        multiBaseToUint8List(proofValue),
      ),
      isTrue,
    );
  });

  test('hashes as the W3C eddsa-jcs-2022 test vector signs', () async {
    // https://github.com/w3c/vc-di-eddsa/tree/main/TestVectors
    final privateKey = multiBaseToUint8List(
      'z3u2en7t5LR2WtQH5PfFqMqwVHBeXouLzo6haApm8XHqvjxq',
    );
    final keyPair = Ed25519KeyPair.fromSeed(
      Uint8List.sublistView(privateKey, 2),
    );
    const context = [
      'https://www.w3.org/ns/credentials/v2',
      'https://www.w3.org/ns/credentials/examples/v2',
    ];
    final credential = {
      '@context': context,
      'id': 'urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33',
      'type': ['VerifiableCredential', 'AlumniCredential'],
      'name': 'Alumni Credential',
      'description': 'A minimum viable example of an Alumni Credential.',
      'issuer': 'https://vc.example/issuers/5678',
      'validFrom': '2023-01-01T00:00:00Z',
      'credentialSubject': {
        'id': 'did:example:abcdefgh',
        'alumniOf': 'The School of Examples',
      },
    };
    final proofConfig = {
      'type': 'DataIntegrityProof',
      'cryptosuite': 'eddsa-jcs-2022',
      'created': '2023-02-24T23:36:38Z',
      'verificationMethod':
          'did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2'
          '#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2',
      'proofPurpose': 'assertionMethod',
      '@context': context,
    };

    final signature = await keyPair.sign(
      TrustTaskProof.hashData(proofConfig, credential),
      signatureScheme: SignatureScheme.ed25519,
    );

    expect(
      toMultiBase(signature),
      'z2HnFSSPPBzR36zdDgK8PbEHeXbR56YF24jwMpt3R1eHXQzJDMWS93FCzpvJpwTWd3GAVFuU'
      'fjoJdcnTMuVor51aX',
    );
  });

  test('leaves a task unsigned for a key that cannot sign eddsa', () async {
    final (keyPair, _) = P256KeyPair.generate();
    final signer = signerOf(keyPair, SignatureScheme.ecdsa_p256_sha256);
    final unsigned = task(signer.did);

    final result = await TrustTaskProof.sign(unsigned, signer: signer);

    expect(result.proof, isNull);
    expect(result.toJson(), unsigned.toJson());
  });
}
