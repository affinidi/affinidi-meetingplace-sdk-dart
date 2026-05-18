import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/liveness_check_request_payload.dart';
import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_protocol.dart';

/// Reads liveness ZKP attachments from DIDComm [Attachment] lists.
abstract final class LivenessZkpAttachmentParser {
  static bool isRequest(Attachment? attachment) =>
      tryParseRequest(attachment) != null;

  static bool isProof(Attachment? attachment) =>
      tryParseProof(attachment) != null;

  static bool hasRequest(Iterable<Attachment?> attachments) =>
      tryParseRequestIn(attachments) != null;

  static bool hasProof(Iterable<Attachment?> attachments) =>
      tryParseProofIn(attachments) != null;

  static LivenessCheckRequestPayload? tryParseRequest(Attachment? attachment) =>
      tryParseRequestIn([attachment]);

  static LivenessCheckRequestPayload? tryParseRequestIn(
    Iterable<Attachment?> attachments,
  ) => _tryParseFirstAttachment(
    attachments,
    format: LivenessZkpProtocol.livenessCheckRequestFormat,
    fromJson: LivenessCheckRequestPayload.fromJson,
  );

  static LivenessProofPayload? tryParseProof(Attachment? attachment) =>
      tryParseProofIn([attachment]);

  static LivenessProofPayload? tryParseProofIn(
    Iterable<Attachment?> attachments,
  ) => _tryParseFirstAttachment(
    attachments,
    format: LivenessZkpProtocol.livenessProofFormat,
    fromJson: LivenessProofPayload.fromJson,
  );

  /// Scans [attachments] and returns the first payload matching [format].
  static T? _tryParseFirstAttachment<T>(
    Iterable<Attachment?> attachments, {
    required String format,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    for (final attachment in attachments) {
      if (attachment?.format != format) continue;

      final jsonStr = attachment!.data?.json;
      if (jsonStr == null || jsonStr.isEmpty) continue;

      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is! Map<String, dynamic>) continue;
        return fromJson(decoded);
      } on FormatException {
        continue;
      }
    }
    return null;
  }
}
