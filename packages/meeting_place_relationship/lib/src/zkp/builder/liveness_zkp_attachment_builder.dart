import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/liveness_check_request_payload.dart';
import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_protocol.dart';

/// Builds DIDComm [Attachment] lists for liveness ZKP request/proof messages.
abstract final class LivenessZkpAttachmentBuilder {
  static const _mediaType = 'application/json';

  /// One attachment asking the peer to run the liveness + proof flow.
  static List<Attachment> buildLivenessCheckRequest({
    String? attachmentId,
    DateTime? lastModified,
  }) => [
    _jsonAttachment(
      format: LivenessZkpProtocol.livenessCheckRequestFormat,
      json: jsonEncode(const LivenessCheckRequestPayload().toJson()),
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

  static Attachment _jsonAttachment({
    required String format,
    required String json,
    String? attachmentId,
    DateTime? lastModified,
  }) {
    final id = attachmentId ?? DateTime.now().millisecondsSinceEpoch.toString();
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
