import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../shared/credential_builder.dart';
import '../model/r_card_subject.dart';

/// Builds DIDComm [Attachment]s carrying a signed R-Card VC payload.
class RCardDIDCommAttachmentBuilder {
  RCardDIDCommAttachmentBuilder._();

  /// The DIDComm attachment format identifier for R-Card attachments.
  static const attachmentFormat = 'mpx_r_card_attachment_plugin';

  /// Wraps a raw VC JSON map in a DIDComm [Attachment] list.
  ///
  /// Use this when you already have a signed VC and want to attach it
  /// to a DIDComm message.
  ///
  /// Set [isUpdate] to `true` when the R-Card replaces a previously sent one
  /// (e.g. after a profile update). Defaults to `false`.
  ///
  /// Set [isAutoExchange] to `true` when the R-Card was delivered via the
  /// DIDComm channel-inauguration path (not an explicit send). Defaults to
  /// `false`.
  ///
  /// Both flags are stored in the attachment payload and are read by the app
  /// layer to decide how to render the attachment tile (e.g. suppress duplicate
  /// notifications for auto-exchanged cards). They are not consumed by the SDK.
  static List<Attachment> fromVcJson(
    Map<String, dynamic> vcJson, {
    bool isUpdate = false,
    bool isAutoExchange = false,
  }) {
    final payload = jsonEncode({
      'vcBlob': jsonEncode(vcJson),
      'isUpdate': isUpdate,
      'isAutoExchange': isAutoExchange,
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
  /// - [issuerDid] — DID of the local party whose card is being shared.
  /// - [card] — The contact fields to embed in the R-Card VC.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<List<Attachment>> buildForOwner({
    required String issuerDid,
    required RCardSubject card,
    required DidManager issuerDidManager,
  }) async {
    final vc = await CredentialBuilder.buildRCard(
      issuerDid: issuerDid,
      subjectDid: issuerDid,
      subject: card,
      issuerDidManager: issuerDidManager,
    );

    return fromVcJson(vc.toJson());
  }
}
