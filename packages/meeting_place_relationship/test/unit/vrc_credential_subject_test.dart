import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:meeting_place_relationship/src/models/vrc/vrc_credential_subject.dart';
import 'package:test/test.dart';

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
}
