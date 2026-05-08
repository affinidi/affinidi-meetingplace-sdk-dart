import 'dart:convert';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('RCardDIDCommAttachmentBuilder', () {
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
