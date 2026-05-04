import 'dart:convert';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';

void main() {
  final parser = RCardParser();

  group('RCardParser', () {
    test('invalid JSON vcBlob returns null', () async {
      final result = await parser.parse(
        vcBlob: 'not-json',
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC type missing VerifiableCredential returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['type'] = ['RelationshipCard'];
      final result = await parser.parse(
        vcBlob: jsonEncode(vcJson),
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC type missing RelationshipCard returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['type'] = ['VerifiableCredential'];
      final result = await parser.parse(
        vcBlob: jsonEncode(vcJson),
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC context missing R-Card URL returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['@context'] = ['https://www.w3.org/2018/credentials/v1'];
      final result = await parser.parse(
        vcBlob: jsonEncode(vcJson),
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC with no proof returns null', () async {
      final result = await parser.parse(
        vcBlob: rCardVcBlob,
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC missing credentialSubject.id returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['credentialSubject'] = <String, dynamic>{};
      final result = await parser.parse(
        vcBlob: jsonEncode(vcJson),
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });
  });

  group('RCardParser happy path', () {
    late String vcBlob;
    late String issuerDid;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      issuerDid = didDoc.id;

      final vc = await CredentialBuilder.buildRCard(
        issuerDid: issuerDid,
        subjectDid: issuerDid,
        subject: const RCardSubject(firstName: 'Test', lastName: 'User'),
        issuerDidManager: didManager,
      );
      vcBlob = jsonEncode(vc.toJson());
    });

    test('valid signed R-Card returns a ReceivedRCard', () async {
      final result = await parser.parse(
        vcBlob: vcBlob,
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNotNull);
      expect(result!.issuerDid, issuerDid);
      expect(result.subjectDid, issuerDid);
      expect(result.version, RCardConstants.receivedRCardVersion);
    });
  });
}
