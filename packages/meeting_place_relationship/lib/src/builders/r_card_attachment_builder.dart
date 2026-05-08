import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../models/persona_did.dart';
import '../models/r_card/r_card_subject.dart';
import 'credential_builder.dart';

/// Builds DIDComm [Attachment]s carrying a signed R-Card VC payload.
class RCardAttachmentBuilder {
  RCardAttachmentBuilder._();

  /// The DIDComm attachment format identifier for R-Card attachments.
  static const attachmentFormat = 'mpx_r_card_attachment_plugin';

  /// Wraps a raw VC JSON map in a DIDComm [Attachment] list.
  ///
  /// Use this when you already have a signed VC and want to attach it
  /// to a DIDComm message.
  static List<Attachment> fromVcJson(Map<String, dynamic> vcJson) {
    final payload = jsonEncode({
      'vcBlob': jsonEncode(vcJson),
      'isUpdate': false,
    });

    return [
      Attachment(
        id: const Uuid().v4(),
        mediaType: 'application/json',
        format: attachmentFormat,
        lastModifiedTime: DateTime.now().toUtc(),
        data: AttachmentData(json: payload),
      ),
    ];
  }

  /// Builds and signs an R-Card and returns it as a DIDComm attachment list.
  ///
  /// - [persona] — The identity of the user sharing their card.
  /// - [card] — The contact fields to embed in the R-Card VC.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<List<Attachment>> buildForPersona({
    required PersonaDid persona,
    required RCardSubject card,
    required DidManager issuerDidManager,
  }) async {
    final vc = await CredentialBuilder.buildRCard(
      issuerDid: persona.did,
      subjectDid: persona.did,
      subject: card,
      issuerDidManager: issuerDidManager,
    );

    return fromVcJson(vc.toJson());
  }
}
