import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('RCardSubject', () {
    test('fromVcBlob returns null for invalid input', () {
      expect(RCardSubject.fromVcBlob('not-json'), isNull);
      expect(RCardSubject.fromVcBlob('{}'), isNull);
    });

    test('name concatenates first and last name', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      expect(subject.name, 'Alice Smith');
    });

    test('name trims whitespace and skips nulls', () {
      const subject = RCardSubject(firstName: ' Bob ', lastName: null);
      expect(subject.name, 'Bob');
    });
  });

  group('RCardVCardExtension', () {
    test('toVCard contains BEGIN and END markers', () {
      const subject = RCardSubject(
        firstName: 'Alice',
        lastName: 'Smith',
        email: 'alice@example.com',
      );
      final vCard = subject.toVCard();
      expect(vCard, contains('BEGIN:VCARD'));
      expect(vCard, contains('END:VCARD'));
      expect(vCard, contains('EMAIL:alice@example.com'));
    });
  });

  group('ReceivedRCard', () {
    test('fromVcBlob returns null for invalid JSON', () {
      expect(ReceivedRCard.fromVcBlob('did:example:1', 'bad'), isNull);
    });

    test('fromVcBlob returns null when issuer is missing', () {
      const blob = '{"credentialSubject": {}}';
      expect(ReceivedRCard.fromVcBlob('did:example:1', blob), isNull);
    });

    test('fromVcBlob parses a minimal valid blob', () {
      const blob =
          '{"issuer": "did:example:issuer", "validFrom": "2024-01-01T00:00:00Z"}';
      final card = ReceivedRCard.fromVcBlob('did:example:holder', blob);
      expect(card, isNotNull);
      expect(card!.issuerDid, 'did:example:issuer');
      expect(card.subjectDid, 'did:example:holder');
    });
  });

  group('RelationshipCredentialConstants', () {
    test('typeRCard is correct', () {
      expect(RelationshipCredentialConstants.typeRCard, 'RelationshipCard');
    });

    test('typeRelationshipCredential is correct', () {
      expect(
        RelationshipCredentialConstants.typeRelationshipCredential,
        'RelationshipCredential',
      );
    });
  });

  group('PersonaDid', () {
    test('equality holds when did and name match', () {
      const a = PersonaDid(did: 'did:example:1', name: 'Alice');
      const b = PersonaDid(did: 'did:example:1', name: 'Alice');
      expect(a, equals(b));
    });

    test('inequality when did differs', () {
      const a = PersonaDid(did: 'did:example:1', name: 'Alice');
      const b = PersonaDid(did: 'did:example:2', name: 'Alice');
      expect(a, isNot(equals(b)));
    });
  });

  group('VrcExchangeRole', () {
    test('has initiator and responder values', () {
      expect(
        VrcExchangeRole.values,
        containsAll([VrcExchangeRole.initiator, VrcExchangeRole.responder]),
      );
    });
  });
}
