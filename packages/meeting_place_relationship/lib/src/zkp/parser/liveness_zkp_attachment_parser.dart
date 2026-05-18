import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/liveness_check_request_payload.dart';
import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_protocol.dart';

/// Reads liveness ZKP attachments from DIDComm [Attachment] lists.
abstract final class LivenessZkpAttachmentParser {
  static MeetingPlaceCoreSDKLogger logger = DefaultMeetingPlaceCoreSDKLogger(
    className: 'LivenessZkpAttachmentParser',
  );

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
  ) => _firstParsed(
    attachments,
    format: LivenessZkpProtocol.livenessCheckRequestFormat,
    fromJson: LivenessCheckRequestPayload.fromJson,
  );

  static LivenessProofPayload? tryParseProof(Attachment? attachment) =>
      tryParseProofIn([attachment]);

  static LivenessProofPayload? tryParseProofIn(
    Iterable<Attachment?> attachments,
  ) => _firstParsed(
    attachments,
    format: LivenessZkpProtocol.livenessProofFormat,
    fromJson: LivenessProofPayload.fromJson,
  );

  static T? _firstParsed<T>(
    Iterable<Attachment?> attachments, {
    required String format,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    for (final attachment in attachments) {
      if (attachment?.format != format) continue;
      final parsed = _parseJson(attachment!, fromJson);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static T? _parseJson<T>(
    Attachment attachment,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final jsonStr = attachment.data?.json;
    if (jsonStr == null || jsonStr.isEmpty) return null;

    final id = attachment.id;

    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        logger.debug('Attachment $id: JSON body is not an object');
        return null;
      }
      body = decoded;
    } on FormatException catch (e) {
      logger.debug('Attachment $id: malformed JSON $e');
      return null;
    }

    try {
      return fromJson(body);
    } on FormatException catch (e) {
      logger.debug('Attachment $id: invalid liveness payload $e');
      return null;
    } catch (e) {
      logger.debug('Attachment $id: unexpected error $e');
      return null;
    }
  }
}
