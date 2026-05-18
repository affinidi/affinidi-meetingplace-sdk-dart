import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_constants.dart';

/// Reads liveness ZKP attachments from DIDComm [Attachment] lists.
abstract final class LivenessZkpAttachmentParser {
  static bool isLivenessCheckRequest(Attachment? attachment) =>
      attachment?.format == LivenessZkpConstants.livenessCheckRequestFormat;

  static bool isLivenessProof(Attachment? attachment) =>
      attachment?.format == LivenessZkpConstants.livenessProofFormat;

  static bool hasLivenessCheckRequest(Iterable<Attachment?> attachments) =>
      attachments.any(isLivenessCheckRequest);

  static bool hasLivenessProof(Iterable<Attachment?> attachments) =>
      attachments.any(isLivenessProof);

  /// Returns the first valid liveness proof payload, or `null` if none found.
  static LivenessProofPayload? tryParseLivenessProofPayload(
    Iterable<Attachment?> attachments,
  ) {
    for (final attachment in attachments) {
      if (!isLivenessProof(attachment)) continue;

      final jsonStr = attachment!.data?.json;
      if (jsonStr == null || jsonStr.isEmpty) continue;

      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is! Map<String, dynamic>) continue;
        return LivenessProofPayload.fromJson(decoded);
      } on FormatException {
        continue;
      } on Object {
        continue;
      }
    }
    return null;
  }
}
