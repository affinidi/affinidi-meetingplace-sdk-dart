import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../builders/r_card_attachment_builder.dart';
import '../models/credential_constants.dart';
import '../models/r_card/received_r_card.dart';

/// Parses DIDComm [Attachment]s and extracts valid R-Card credentials.
///
/// Performs format validation, type and context checks, signature
/// verification, and constructs a [ReceivedRCard] from the verified VC.
/// Storage is left entirely to the consumer.
class RCardAttachmentParser {
  RCardAttachmentParser._();

  /// Returns the first valid [ReceivedRCard] found in [attachments].
  ///
  /// Skips attachments with an unrecognised format and returns `null`
  /// if no valid R-Card is found.
  ///
  /// - [attachments] — DIDComm attachments to inspect.
  /// - [contactChannelDid] — The other party's permanent channel DID,
  ///   stored on the result for later lookup.
  static Future<ReceivedRCard?> parseFirst({
    required List<Attachment> attachments,
    required String contactChannelDid,
  }) async {
    for (final attachment in attachments) {
      final result = await _tryParse(
        attachment: attachment,
        contactChannelDid: contactChannelDid,
      );
      if (result != null) return result;
    }
    return null;
  }

  static Future<ReceivedRCard?> _tryParse({
    required Attachment attachment,
    required String contactChannelDid,
  }) async {
    if (attachment.format != RCardAttachmentBuilder.attachmentFormat) {
      return null;
    }

    final rawJson = attachment.data?.json;
    if (rawJson == null) return null;

    final dynamic payload;
    try {
      payload = jsonDecode(rawJson);
    } catch (_) {
      return null;
    }
    if (payload is! Map) return null;

    final vcBlob = payload['vcBlob'];
    if (vcBlob is! String) return null;

    final dynamic decoded;
    try {
      decoded = jsonDecode(vcBlob);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    // Validate VC type
    final types = (decoded['type'] as List?)?.map((e) => e.toString()).toSet();
    if (types == null ||
        !types.contains(
          RelationshipCredentialConstants.typeVerifiableCredential,
        ) ||
        !types.contains(RelationshipCredentialConstants.typeRCard)) {
      return null;
    }

    // Validate VC context
    final context = decoded['@context'];
    final contextList = context is List
        ? context.map((e) => e.toString()).toList()
        : <String>[];
    if (!contextList.contains(RelationshipCredentialConstants.contextRCard)) {
      return null;
    }

    // Parse and verify signature
    late ParsedVerifiableCredential parsedVc;
    try {
      parsedVc = UniversalParser.parse(vcBlob);
    } catch (_) {
      return null;
    }
    final verification = await UniversalVerifier().verify(parsedVc);
    if (!verification.isValid) return null;

    // Extract required fields
    final subject = decoded['credentialSubject'];
    final String? subjectDid;
    if (subject is Map) {
      subjectDid = subject['id']?.toString();
    } else if (subject is List && subject.isNotEmpty && subject.first is Map) {
      subjectDid = (subject.first as Map)['id']?.toString();
    } else {
      subjectDid = null;
    }
    if (subjectDid == null || subjectDid.isEmpty) return null;

    final issuer = decoded['issuer'];
    final issuerDid = issuer is String
        ? issuer
        : (issuer is Map ? issuer['id']?.toString() : null);
    if (issuerDid == null || issuerDid.isEmpty) return null;

    final rawDate = decoded['validFrom'];
    final issuanceDate = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final now = DateTime.now().toUtc();

    return ReceivedRCard(
      subjectDid: subjectDid,
      vcBlob: vcBlob,
      issuerDid: issuerDid,
      version: 2,
      issuanceDate: issuanceDate ?? now,
      receivedAt: now,
      contactChannelDid: contactChannelDid.isEmpty ? null : contactChannelDid,
    );
  }
}
