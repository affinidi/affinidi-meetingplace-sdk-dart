import 'dart:convert';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/vrc_fixture.dart';

void main() {
  late VrcParser parser;

  setUp(() {
    parser = VrcParser();
  });

  group('VrcParser', () {
    test('returns null for empty string', () async {
      final result = await parser.parse(vcBlob: '');
      expect(result, isNull);
    });

    test('returns null for invalid JSON', () async {
      final result = await parser.parse(vcBlob: 'not-json');
      expect(result, isNull);
    });

    test('returns null for VC missing RelationshipCredential type', () async {
      final result = await parser.parse(vcBlob: vrcBlobMissingType);
      expect(result, isNull);
    });

    test('returns null for VRC blob without proof', () async {
      final result = await parser.parse(vcBlob: vrcBlobWithoutProof);
      expect(result, isNull);
    });

    test('returns null for VRC blob without id', () async {
      final result = await parser.parse(vcBlob: vrcBlobWithoutId);
      expect(result, isNull);
    });

    group('happy path', () {
      late DidKeyManager issuerManager;
      late String issuerDid;

      setUpAll(() async {
        final wallet = PersistentWallet(InMemoryKeyStore());
        issuerManager = DidKeyManager(
          wallet: wallet,
          store: InMemoryDidStore(),
        );
        final keyPair = await wallet.generateKey();
        await issuerManager.addVerificationMethod(keyPair.id);
        final didDoc = await issuerManager.getDidDocument();
        issuerDid = didDoc.id;
      });

      test(
        'returns ParsedVerifiableCredential for a valid signed VRC',
        () async {
          const counterpartDid = 'did:key:z6MkTestCounterpart';
          final subject = VrcCredentialSubject(
            from: VrcParty(did: issuerDid, name: 'Alice'),
            to: const VrcParty(did: counterpartDid, name: 'Bob'),
          );
          final signed = await CredentialBuilder.buildVrc(
            issuerDid: issuerDid,
            subject: subject,
            issuerDidManager: issuerManager,
          );
          final vcBlob = jsonEncode(signed.toJson());

          final result = await parser.parse(vcBlob: vcBlob);

          expect(result, isNotNull);
        },
      );
    });
  });
}
