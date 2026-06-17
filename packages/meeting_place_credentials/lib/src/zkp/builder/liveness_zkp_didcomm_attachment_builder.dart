import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../model/liveness_check_request_payload.dart';
import '../model/liveness_declined_payload.dart';
import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_protocol.dart';

/// Builds DIDComm [Attachment] lists for liveness ZKP request/proof messages.
abstract final class LivenessZkpDIDCommAttachmentBuilder {
  static const _mediaType = 'application/json';

  /// One attachment asking the peer to run the liveness + proof flow.
  static List<Attachment> buildLivenessCheckRequest({
    required String challengeNonceHex,
    String? attachmentId,
    DateTime? lastModified,
  }) => [
    _jsonAttachment(
      format: LivenessZkpProtocol.livenessCheckRequestFormat,
      json: jsonEncode(
        LivenessCheckRequestPayload(
          challengeNonceHex: challengeNonceHex,
        ).toJson(),
      ),
      attachmentId: attachmentId,
      lastModified: lastModified,
    ),
  ];

  /// One attachment carrying a generated liveness proof.
  static List<Attachment> buildLivenessProof({
    required LivenessProofPayload payload,
    String? attachmentId,
    DateTime? lastModified,
  }) => [
    _jsonAttachment(
      format: LivenessZkpProtocol.livenessProofFormat,
      json: jsonEncode(payload.toJson()),
      attachmentId: attachmentId,
      lastModified: lastModified,
    ),
  ];

  static List<Attachment> buildLivenessDeclined({
    String? attachmentId,
    DateTime? lastModified,
  }) => [
    _jsonAttachment(
      format: LivenessZkpProtocol.livenessDeclinedFormat,
      json: jsonEncode(const LivenessDeclinedPayload().toJson()),
      attachmentId: attachmentId,
      lastModified: lastModified,
    ),
  ];

  static Attachment _jsonAttachment({
    required String format,
    required String json,
    String? attachmentId,
    DateTime? lastModified,
  }) {
    final id = attachmentId ?? const Uuid().v4();
    final when = (lastModified ?? DateTime.now()).toUtc();

    return Attachment(
      id: id,
      mediaType: _mediaType,
      format: format,
      lastModifiedTime: when,
      data: AttachmentData(json: json),
    );
  }
}
