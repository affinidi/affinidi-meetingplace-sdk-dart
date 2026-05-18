import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/liveness_check_request_payload.dart';
import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_protocol.dart';

/// Reads liveness ZKP attachments from DIDComm [Attachment] lists.
class LivenessZkpAttachmentParser {
  LivenessZkpAttachmentParser({MeetingPlaceCoreSDKLogger? logger})
    : _logger =
          logger ??
          DefaultMeetingPlaceCoreSDKLogger(
            className: 'LivenessZkpAttachmentParser',
          );

  final MeetingPlaceCoreSDKLogger _logger;

  static final LivenessZkpAttachmentParser instance =
      LivenessZkpAttachmentParser();

  static bool matchesRequestFormat(Attachment? attachment) =>
      attachment?.format == LivenessZkpProtocol.livenessCheckRequestFormat;

  static bool matchesProofFormat(Attachment? attachment) =>
      attachment?.format == LivenessZkpProtocol.livenessProofFormat;

  static bool hasRequestFormat(Iterable<Attachment?> attachments) =>
      attachments.any(matchesRequestFormat);

  static bool hasProofFormat(Iterable<Attachment?> attachments) =>
      attachments.any(matchesProofFormat);

  static bool isRequest(Attachment? attachment) =>
      tryParseRequest(attachment) != null;

  static bool isProof(Attachment? attachment) =>
      tryParseProof(attachment) != null;

  static bool hasRequest(Iterable<Attachment?> attachments) =>
      tryParseRequestIn(attachments) != null;

  static bool hasProof(Iterable<Attachment?> attachments) =>
      tryParseProofIn(attachments) != null;

  static LivenessCheckRequestPayload? tryParseRequest(Attachment? attachment) =>
      instance.parseRequest(attachment);

  static LivenessCheckRequestPayload? tryParseRequestIn(
    Iterable<Attachment?> attachments,
  ) => instance.parseRequestIn(attachments);

  static LivenessProofPayload? tryParseProof(Attachment? attachment) =>
      instance.parseProof(attachment);

  static LivenessProofPayload? tryParseProofIn(
    Iterable<Attachment?> attachments,
  ) => instance.parseProofIn(attachments);

  LivenessCheckRequestPayload? parseRequest(Attachment? attachment) =>
      parseRequestIn([attachment]);

  LivenessCheckRequestPayload? parseRequestIn(
    Iterable<Attachment?> attachments,
  ) => _firstParsed(
    attachments,
    format: LivenessZkpProtocol.livenessCheckRequestFormat,
    fromJson: LivenessCheckRequestPayload.fromJson,
  );

  LivenessProofPayload? parseProof(Attachment? attachment) =>
      parseProofIn([attachment]);

  LivenessProofPayload? parseProofIn(Iterable<Attachment?> attachments) =>
      _firstParsed(
        attachments,
        format: LivenessZkpProtocol.livenessProofFormat,
        fromJson: LivenessProofPayload.fromJson,
      );
  T? _firstParsed<T>(
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

  T? _parseJson<T>(
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
        _logger.debug('Attachment $id: JSON body is not an object');
        return null;
      }
      body = decoded;
    } on FormatException catch (e) {
      _logger.debug('Attachment $id: malformed JSON $e');
      return null;
    }

    try {
      return fromJson(body);
    } on FormatException catch (e) {
      _logger.debug('Attachment $id: invalid liveness payload $e');
      return null;
    } catch (e) {
      _logger.debug('Attachment $id: unexpected error $e');
      return null;
    }
  }
}
