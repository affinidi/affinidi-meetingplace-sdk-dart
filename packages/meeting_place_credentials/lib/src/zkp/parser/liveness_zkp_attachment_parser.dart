import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/liveness_check_request_payload.dart';
import '../model/liveness_declined_payload.dart';
import '../model/liveness_proof_payload.dart';
import '../model/liveness_zkp_protocol.dart';

/// Reads liveness request and proof attachments from DIDComm [Attachment]
/// lists.
class LivenessZkpAttachmentParser {
  /// Creates a parser that logs failures using the provided logger.
  LivenessZkpAttachmentParser({MeetingPlaceCoreSDKLogger? logger})
    : _logger =
          logger ??
          DefaultMeetingPlaceCoreSDKLogger(
            className: 'LivenessZkpAttachmentParser',
          );

  final MeetingPlaceCoreSDKLogger _logger;

  /// Shared parser instance with default logging.
  static final LivenessZkpAttachmentParser instance =
      LivenessZkpAttachmentParser();

  /// Returns true when the attachment format matches a liveness request.
  static bool matchesRequestFormat(Attachment? attachment) =>
      attachment?.format == LivenessZkpProtocol.livenessCheckRequestFormat;

  /// Returns true when the attachment format matches a liveness proof.
  static bool matchesProofFormat(Attachment? attachment) =>
      attachment?.format == LivenessZkpProtocol.livenessProofFormat;

  /// Returns true when the attachment format matches a liveness declined event.
  static bool matchesDeclinedFormat(Attachment? attachment) =>
      attachment?.format == LivenessZkpProtocol.livenessDeclinedFormat;

  /// Returns true when any attachment has the liveness request format.
  static bool hasRequestFormat(Iterable<Attachment?> attachments) =>
      attachments.any(matchesRequestFormat);

  /// Returns true when any attachment has the liveness proof format.
  static bool hasProofFormat(Iterable<Attachment?> attachments) =>
      attachments.any(matchesProofFormat);

  /// Returns true when any attachment has the liveness declined format.
  static bool hasDeclinedFormat(Iterable<Attachment?> attachments) =>
      attachments.any(matchesDeclinedFormat);

  /// Returns true when the attachment parses as a liveness request.
  static bool isRequest(Attachment? attachment) =>
      tryParseRequest(attachment) != null;

  /// Returns true when the attachment parses as a liveness proof.
  static bool isProof(Attachment? attachment) =>
      tryParseProof(attachment) != null;

  /// Returns true when the attachment parses as a liveness declined payload.
  static bool isDeclined(Attachment? attachment) =>
      tryParseDeclined(attachment) != null;

  /// Returns true when any attachment in the list parses as a liveness request.
  static bool hasRequest(Iterable<Attachment?> attachments) =>
      tryParseRequestIn(attachments) != null;

  /// Returns true when any attachment in the list parses as a liveness proof.
  static bool hasProof(Iterable<Attachment?> attachments) =>
      tryParseProofIn(attachments) != null;

  /// Returns true when any attachment parses as a liveness declined payload.
  static bool hasDeclined(Iterable<Attachment?> attachments) =>
      tryParseDeclinedIn(attachments) != null;

  /// Attempts to parse a single attachment as a liveness request payload.
  static LivenessCheckRequestPayload? tryParseRequest(Attachment? attachment) =>
      instance.parseRequest(attachment);

  /// Attempts to parse the first matching attachment as a liveness request
  /// payload.
  static LivenessCheckRequestPayload? tryParseRequestIn(
    Iterable<Attachment?> attachments,
  ) => instance.parseRequestIn(attachments);

  /// Attempts to parse a single attachment as a liveness proof payload.
  static LivenessProofPayload? tryParseProof(Attachment? attachment) =>
      instance.parseProof(attachment);

  /// Attempts to parse a single attachment as a liveness declined payload.
  static LivenessDeclinedPayload? tryParseDeclined(Attachment? attachment) =>
      instance.parseDeclined(attachment);

  /// Attempts to parse the first matching attachment as a liveness proof
  /// payload.
  static LivenessProofPayload? tryParseProofIn(
    Iterable<Attachment?> attachments,
  ) => instance.parseProofIn(attachments);

  /// Attempts to parse the first matching attachment as a liveness declined
  /// payload.
  static LivenessDeclinedPayload? tryParseDeclinedIn(
    Iterable<Attachment?> attachments,
  ) => instance.parseDeclinedIn(attachments);

  /// Parses a single attachment as a liveness request payload.
  LivenessCheckRequestPayload? parseRequest(Attachment? attachment) =>
      parseRequestIn([attachment]);

  /// Parses the first matching attachment as a liveness request payload.
  LivenessCheckRequestPayload? parseRequestIn(
    Iterable<Attachment?> attachments,
  ) => _firstParsed(
    attachments,
    format: LivenessZkpProtocol.livenessCheckRequestFormat,
    fromJson: LivenessCheckRequestPayload.fromJson,
  );

  /// Parses a single attachment as a liveness proof payload.
  LivenessProofPayload? parseProof(Attachment? attachment) =>
      parseProofIn([attachment]);

  /// Parses a single attachment as a liveness declined payload.
  LivenessDeclinedPayload? parseDeclined(Attachment? attachment) =>
      parseDeclinedIn([attachment]);

  /// Parses the first matching attachment as a liveness proof payload.
  LivenessProofPayload? parseProofIn(Iterable<Attachment?> attachments) =>
      _firstParsed(
        attachments,
        format: LivenessZkpProtocol.livenessProofFormat,
        fromJson: LivenessProofPayload.fromJson,
      );

  /// Parses the first matching attachment as a liveness declined payload.
  LivenessDeclinedPayload? parseDeclinedIn(Iterable<Attachment?> attachments) =>
      _firstParsed(
        attachments,
        format: LivenessZkpProtocol.livenessDeclinedFormat,
        fromJson: LivenessDeclinedPayload.fromJson,
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
