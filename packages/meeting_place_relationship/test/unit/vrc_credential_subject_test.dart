import 'dart:convert';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/vrc_fixture.dart';

void main() {
  group('VrcParty', () {
    test('stores did and name', () {
      const party = VrcParty(did: 'did:key:z1', name: 'Alice');
      expect(party.did, 'did:key:z1');
      expect(party.name, 'Alice');
    });

    test('equality — same did and name are equal', () {
      const a = VrcParty(did: 'did:key:z1', name: 'Alice');
      const b = VrcParty(did: 'did:key:z1', name: 'Alice');
      expect(a, equals(b));
    });

    test('equality — different did are not equal', () {
      const a = VrcParty(did: 'did:key:z1', name: 'Alice');
      const b = VrcParty(did: 'did:key:z2', name: 'Alice');
      expect(a, isNot(equals(b)));
    });

    test('equality — different name are not equal', () {
      const a = VrcParty(did: 'did:key:z1', name: 'Alice');
      const b = VrcParty(did: 'did:key:z1', name: 'Bob');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = VrcParty(did: 'did:key:z1', name: 'Alice');
      const b = VrcParty(did: 'did:key:z1', name: 'Alice');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes did and name', () {
      const party = VrcParty(did: 'did:key:z1', name: 'Alice');
      expect(party.toString(), contains('did:key:z1'));
      expect(party.toString(), contains('Alice'));
    });
  });

  group('VrcCredentialSubject', () {
    const alice = VrcParty(did: 'did:key:alice', name: 'Alice');
    const bob = VrcParty(did: 'did:key:bob', name: 'Bob');

    test('stores from and to parties', () {
      const subject = VrcCredentialSubject(from: alice, to: bob);
      expect(subject.from, alice);
      expect(subject.to, bob);
    });

    test('toJson produces correct structure', () {
      const subject = VrcCredentialSubject(from: alice, to: bob);
      final json = subject.toJson();
      expect(json['from'], {'did': 'did:key:alice', 'name': 'Alice'});
      expect(json['to'], {'did': 'did:key:bob', 'name': 'Bob'});
    });

    test('equality — same from and to are equal', () {
      const a = VrcCredentialSubject(from: alice, to: bob);
      const b = VrcCredentialSubject(from: alice, to: bob);
      expect(a, equals(b));
    });

    test('equality — different to party are not equal', () {
      const carol = VrcParty(did: 'did:key:carol', name: 'Carol');
      const a = VrcCredentialSubject(from: alice, to: bob);
      const b = VrcCredentialSubject(from: alice, to: carol);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = VrcCredentialSubject(from: alice, to: bob);
      const b = VrcCredentialSubject(from: alice, to: bob);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes from and to', () {
      const subject = VrcCredentialSubject(from: alice, to: bob);
      expect(subject.toString(), contains('alice'));
      expect(subject.toString(), contains('bob'));
    });
  });

  group('VrcCredentialSubject.fromVcBlob', () {
    late String validVrcBlob;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final issuerManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await issuerManager.addVerificationMethod(keyPair.id);
      final issuerDid = (await issuerManager.getDidDocument()).id;

      final signed = await CredentialBuilder.buildVrc(
        issuerDid: issuerDid,
        subject: VrcCredentialSubject(
          from: VrcParty(did: issuerDid, name: 'Alice'),
          to: const VrcParty(did: 'did:key:z6MkBob', name: 'Bob'),
        ),
        issuerDidManager: issuerManager,
      );
      validVrcBlob = jsonEncode(signed.toJson());
    });

    test('parses from/to parties from a valid signed VRC blob', () {
      final subject = VrcCredentialSubject.fromVcBlob(validVrcBlob);
      expect(subject.from.name, 'Alice');
      expect(subject.to.did, 'did:key:z6MkBob');
      expect(subject.to.name, 'Bob');
    });

    test('throws FormatException for invalid JSON', () {
      expect(
        () => VrcCredentialSubject.fromVcBlob('not-json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for non-DM-v2 blob', () {
      expect(
        () => VrcCredentialSubject.fromVcBlob(vrcBlobMissingType),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for a DM v1 VRC blob', () {
      const v1Blob =
          '{"@context":["https://www.w3.org/2018/credentials/v1",'
          '"https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld"],'
          '"type":["VerifiableCredential","RelationshipCredential"],'
          '"issuer":"did:example:issuer",'
          '"issuanceDate":"2024-01-01T00:00:00Z",'
          '"credentialSubject":{"from":{"did":"did:key:alice","name":"Alice"},'
          '"to":{"did":"did:key:bob","name":"Bob"}}}'
          '}'; // DM v1 — tryParse must reject this
      expect(
        () => VrcCredentialSubject.fromVcBlob(v1Blob),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for blob with malformed'
        ' credentialSubject', () {
      const malformed =
          '{"@context":["https://www.w3.org/2018/credentials/v2",'
          '"https://w3id.org/security/data-integrity/v2",'
          '"https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld"],'
          '"type":["VerifiableCredential","RelationshipCredential"],'
          '"issuer":"did:key:test",'
          '"validFrom":"2024-01-01T00:00:00Z",'
          '"credentialSubject":{"not-from":"x"}}';
      expect(
        () => VrcCredentialSubject.fromVcBlob(malformed),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
