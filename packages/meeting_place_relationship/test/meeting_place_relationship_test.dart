import 'dart:convert';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

void main() {
  group('RCardSubject', () {
    test('fromVcBlob throws FormatException for invalid input', () {
      expect(() => RCardSubject.fromVcBlob('not-json'), throwsFormatException);
      expect(() => RCardSubject.fromVcBlob('{}'), throwsFormatException);
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

  group('RCard', () {
    test('fromVcBlob returns null for invalid JSON', () {
      expect(RCard.fromVcBlob('did:example:1', 'bad'), isNull);
    });

    test('fromVcBlob returns null when issuer is missing', () {
      const blob = '{"credentialSubject": {}}';
      expect(RCard.fromVcBlob('did:example:1', blob), isNull);
    });

    test('fromVcBlob parses a minimal valid blob', () async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      final issuerDid = didDoc.id;
      final vc = await CredentialBuilder.buildRCard(
        issuerDid: issuerDid,
        subjectDid: 'did:example:holder',
        subject: const RCardSubject(firstName: 'Alice'),
        issuerDidManager: didManager,
      );
      expect(
        vc,
        isA<VcDataModelV2>(),
        reason: 'RCardBuilder must produce a DM v2 credential',
      );

      final card = RCard.fromVcBlob(
        'did:example:holder',
        jsonEncode(vc.toJson()),
      );
      expect(card, isNotNull);
      expect(card!.issuerDid, issuerDid);
      expect(card.subjectDid, 'did:example:holder');
    });
  });

  group('RelationshipCredentialConstants', () {
    test('typeRCard is correct', () {
      expect(RCardConstants.typeRCard, 'RelationshipCard');
    });

    test('typeRelationshipCredential is correct', () {
      expect(VrcConstants.typeRelationshipCredential, 'RelationshipCredential');
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
