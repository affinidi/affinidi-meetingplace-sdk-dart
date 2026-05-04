import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';

const rCardVcBlob =
    '{'
    '"@context":["https://www.w3.org/2018/credentials/v2",'
    '"https://w3id.org/security/data-integrity/v2",'
    '"https://schema.affinidi.io/TRelationshipCardV1R0.jsonld"],'
    '"type":["VerifiableCredential","RelationshipCard"],'
    '"issuer":"did:example:issuer",'
    '"validFrom":"2024-01-01T00:00:00Z",'
    '"credentialSubject":{"id":"did:example:subject"}'
    '}';

Attachment makeAttachment({required String format, String? dataJson}) {
  return Attachment(
    id: 'test-id',
    mediaType: 'application/json',
    format: format,
    lastModifiedTime: DateTime(2024),
    data: dataJson != null ? AttachmentData(json: dataJson) : null,
  );
}

Attachment rCardAttachment({String? overrideDataJson}) {
  final data =
      overrideDataJson ??
      jsonEncode({'vcBlob': rCardVcBlob, 'isUpdate': false});
  return makeAttachment(
    format: RCardDIDCommAttachmentBuilder.attachmentFormat,
    dataJson: data,
  );
}
