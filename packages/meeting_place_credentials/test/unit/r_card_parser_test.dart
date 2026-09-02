import 'dart:convert';

import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/rcard/builder/r_card_builder.dart';
import 'package:meeting_place_credentials/src/rcard/parser/r_card_parser.dart';
import 'package:meeting_place_credentials/src/shared/credential_signer.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';

void main() {
  final parser = RCardParser();

  group('RCardParser', () {
    test('invalid JSON vcBlob is rejected as malformedJson', () async {
      final result = await parser.parse(vcBlob: 'not-json');
      expect(result, isA<RCardParseFailure>());
      expect(
        (result as RCardParseFailure).reason,
        RCardRejectionReason.malformedJson,
      );
    });

    test(
      'VC type missing VerifiableCredential is rejected as invalidType',
      () async {
        final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
        vcJson['type'] = ['RelationshipCard'];
        final result = await parser.parse(vcBlob: jsonEncode(vcJson));
        expect(result, isA<RCardParseFailure>());
        expect(
          (result as RCardParseFailure).reason,
          RCardRejectionReason.invalidType,
        );
      },
    );

    test(
      'VC type missing RelationshipCard is rejected as invalidType',
      () async {
        final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
        vcJson['type'] = ['VerifiableCredential'];
        final result = await parser.parse(vcBlob: jsonEncode(vcJson));
        expect(result, isA<RCardParseFailure>());
        expect(
          (result as RCardParseFailure).reason,
          RCardRejectionReason.invalidType,
        );
      },
    );

    test(
      'VC context missing R-Card URL is rejected as invalidContext',
      () async {
        final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
        vcJson['@context'] = ['https://www.w3.org/2018/credentials/v1'];
        final result = await parser.parse(vcBlob: jsonEncode(vcJson));
        expect(result, isA<RCardParseFailure>());
        expect(
          (result as RCardParseFailure).reason,
          RCardRejectionReason.invalidContext,
        );
      },
    );

    test('VC with no proof is rejected', () async {
      // No `proof` field, so ssi's UniversalParser cannot even identify a
      // credential suite for it — rejected before verification is reached.
      final result = await parser.parse(vcBlob: rCardVcBlob);
      expect(result, isA<RCardParseFailure>());
      expect(
        (result as RCardParseFailure).reason,
        RCardRejectionReason.malformedJson,
      );
    });

    test('VC missing credentialSubject.id is rejected', () async {
      // Same fixture as above — no `proof`, so this is also rejected before
      // reaching the subjectDid/issuerDid extraction step; kept as a
      // regression test that the missing id doesn't cause a crash instead.
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['credentialSubject'] = <String, dynamic>{};
      final result = await parser.parse(vcBlob: jsonEncode(vcJson));
      expect(result, isA<RCardParseFailure>());
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

    test('valid signed R-Card returns a RCard', () async {
      final result = await parser.parse(vcBlob: vcBlob);
      expect(result, isA<RCardParseSuccess>());
      final rCard = (result as RCardParseSuccess).rCard;
      expect(rCard.issuerDid, issuerDid);
      expect(rCard.subjectDid, issuerDid);
      expect(rCard.version, RCardConstants.receivedRCardVersion);
    });
  });

  group('RCardParser missing subject id', () {
    test('signed R-Card without a credentialSubject.id is rejected as '
        'missingSubjectOrIssuer', () async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      final issuerDid = didDoc.id;

      // Strip credentialSubject.id before signing, so the resulting VC
      // still verifies (signature/expiry/revocation are all satisfied)
      // and only fails RCardParser's own subjectDid extraction check.
      final template = await RCardBuilder.build(
        issuerDid: issuerDid,
        subjectDid: issuerDid,
        subject: const RCardSubject(firstName: 'NoSubjectId'),
        issuerDidManager: didManager,
      );
      final unsignedJson = template.toJson()..remove('proof');
      final subject = unsignedJson['credentialSubject'];
      if (subject is Map) {
        subject.remove('id');
      } else if (subject is List && subject.isNotEmpty) {
        (subject.first as Map).remove('id');
      }
      final unsigned = VcDataModelV2.fromJson(unsignedJson);
      final vc = await CredentialSigner.sign(unsigned, didManager);

      final result = await parser.parse(vcBlob: jsonEncode(vc.toJson()));
      expect(result, isA<RCardParseFailure>());
      expect(
        (result as RCardParseFailure).reason,
        RCardRejectionReason.missingSubjectOrIssuer,
      );
    });
  });

  group('RCardParser expiry', () {
    test('expired R-Card is rejected as verificationFailed', () async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      final issuerDid = didDoc.id;

      final vc = await RCardBuilder.build(
        issuerDid: issuerDid,
        subjectDid: issuerDid,
        subject: const RCardSubject(firstName: 'Expired'),
        issuerDidManager: didManager,
        validUntil: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );

      final result = await parser.parse(vcBlob: jsonEncode(vc.toJson()));
      expect(result, isA<RCardParseFailure>());
      expect(
        (result as RCardParseFailure).reason,
        RCardRejectionReason.verificationFailed,
      );
    });
  });
}
