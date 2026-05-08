import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';

void main() {
  final parser = RCardAttachmentParser();

  group('RCardAttachmentParser', () {
    test('empty attachment list returns null', () async {
      final result = await parser.parseFirst(
        attachments: [],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('wrong attachment format returns null', () async {
      final result = await parser.parseFirst(
        attachments: [makeAttachment(format: 'other_plugin', dataJson: '{}')],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('null data returns null', () async {
      final result = await parser.parseFirst(
        attachments: [
          makeAttachment(
            format: RCardDIDCommAttachmentBuilder.attachmentFormat,
            dataJson: null,
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('non-JSON data.json returns null', () async {
      final result = await parser.parseFirst(
        attachments: [rCardAttachment(overrideDataJson: 'not-json')],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('missing vcBlob key returns null', () async {
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(overrideDataJson: jsonEncode({'isUpdate': false})),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('non-string vcBlob returns null', () async {
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(
            overrideDataJson: jsonEncode({'vcBlob': 42, 'isUpdate': false}),
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('invalid vcBlob JSON returns null', () async {
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(
            overrideDataJson: jsonEncode({
              'vcBlob': 'not-json',
              'isUpdate': false,
            }),
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC type missing VerifiableCredential returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['type'] = ['RelationshipCard'];
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(
            overrideDataJson: jsonEncode({
              'vcBlob': jsonEncode(vcJson),
              'isUpdate': false,
            }),
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC type missing RelationshipCard returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['type'] = ['VerifiableCredential'];
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(
            overrideDataJson: jsonEncode({
              'vcBlob': jsonEncode(vcJson),
              'isUpdate': false,
            }),
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC context missing R-Card URL returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['@context'] = ['https://www.w3.org/2018/credentials/v1'];
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(
            overrideDataJson: jsonEncode({
              'vcBlob': jsonEncode(vcJson),
              'isUpdate': false,
            }),
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC with no proof returns null', () async {
      final result = await parser.parseFirst(
        attachments: [rCardAttachment()],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });

    test('VC missing credentialSubject.id returns null', () async {
      final vcJson = jsonDecode(rCardVcBlob) as Map<String, dynamic>;
      vcJson['credentialSubject'] = <String, dynamic>{};
      final result = await parser.parseFirst(
        attachments: [
          rCardAttachment(
            overrideDataJson: jsonEncode({
              'vcBlob': jsonEncode(vcJson),
              'isUpdate': false,
            }),
          ),
        ],
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNull);
    });
  });

  group('RCardAttachmentParser happy path', () {
    late List<Attachment> signedAttachments;
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
      signedAttachments = RCardAttachmentBuilder.fromVcJson(vc.toJson());
    });

    test('valid signed R-Card returns a ReceivedRCard', () async {
      final result = await parser.parseFirst(
        attachments: signedAttachments,
        contactChannelDid: 'did:example:channel',
      );
      expect(result, isNotNull);
      expect(result!.issuerDid, issuerDid);
      expect(result.subjectDid, issuerDid);
      expect(
        result.version,
        RelationshipCredentialConstants.receivedRCardVersion,
      );
    });
  });
}
