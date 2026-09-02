import 'dart:convert';

import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

Future<DidManager> _createDidManager() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final keyPair = await wallet.generateKey();
  await didManager.addVerificationMethod(keyPair.id);
  return didManager;
}

void main() {
  group('RCardDIDCommAttachmentBuilder', () {
    test(
      'build signs the R-Card with distinct issuerDid and subjectDid',
      () async {
        final issuerDidManager = await _createDidManager();
        final issuerDoc = await issuerDidManager.getDidDocument();
        final issuerDid = issuerDoc.id;
        const subjectDid = 'did:example:subject';

        final attachments = await RCardDIDCommAttachmentBuilder.build(
          issuerDid: issuerDid,
          subjectDid: subjectDid,
          card: const RCardSubject(firstName: 'Alice'),
          issuerDidManager: issuerDidManager,
        );

        final payload =
            jsonDecode(attachments.single.data!.json!) as Map<String, dynamic>;
        final vcJson =
            jsonDecode(payload['vcBlob'] as String) as Map<String, dynamic>;
        final credentialSubject = vcJson['credentialSubject'];
        final subjectId = credentialSubject is List
            ? (credentialSubject.single as Map)['id']
            : (credentialSubject as Map)['id'];
        final issuer = vcJson['issuer'];
        final actualIssuerDid = issuer is String
            ? issuer
            : (issuer as Map)['id'];

        expect(actualIssuerDid, issuerDid);
        expect(subjectId, subjectDid);
        expect(subjectId, isNot(equals(issuerDid)));
      },
    );

    test('attachmentFormat matches the expected plugin identifier', () {
      expect(
        RCardDIDCommAttachmentBuilder.attachmentFormat,
        'mpx_r_card_attachment_plugin',
      );
    });

    test('fromVcJson returns a single-element list', () {
      final attachments = RCardDIDCommAttachmentBuilder.fromVcJson({
        'id': 'urn:test',
      });
      expect(attachments, hasLength(1));
    });

    test('fromVcJson attachment has the correct format', () {
      final attachment = RCardDIDCommAttachmentBuilder.fromVcJson({
        'id': 'urn:test',
      }).first;
      expect(attachment.format, RCardDIDCommAttachmentBuilder.attachmentFormat);
    });

    test('fromVcJson attachment has application/json mediaType', () {
      final attachment = RCardDIDCommAttachmentBuilder.fromVcJson({
        'id': 'urn:test',
      }).first;
      expect(attachment.mediaType, 'application/json');
    });

    test('fromVcJson data.json encodes vcBlob and isUpdate:false', () {
      final vcJson = {
        'type': ['VerifiableCredential'],
        'id': 'urn:x',
      };
      final attachment = RCardDIDCommAttachmentBuilder.fromVcJson(vcJson).first;
      final decoded = jsonDecode(attachment.data!.json!) as Map;
      expect(decoded['vcBlob'], isA<String>());
      expect(decoded['isUpdate'], isFalse);
      final inner = jsonDecode(decoded['vcBlob'] as String) as Map;
      expect(inner['id'], 'urn:x');
    });

    test('fromVcJson attachment id is unique across calls', () {
      final a = RCardDIDCommAttachmentBuilder.fromVcJson({'id': 'urn:a'}).first;
      final b = RCardDIDCommAttachmentBuilder.fromVcJson({'id': 'urn:b'}).first;
      expect(a.id, isNot(equals(b.id)));
    });
  });
}
