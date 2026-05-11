import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../../shared/credential_constants.dart';
import '../model/r_card_constants.dart';
import '../model/received_r_card.dart';

/// Parses R-Card VC blobs and extracts verified [ReceivedRCard] instances.
class RCardParser {
  RCardParser({MeetingPlaceCoreSDKLogger? logger})
    : _logger =
          logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'RCardParser');

  final MeetingPlaceCoreSDKLogger _logger;

  /// Parses [vcBlob] and returns a [ReceivedRCard] if it is a valid,
  /// signature-verified R-Card credential.
  ///
  /// Returns `null` if the blob cannot be decoded, type or context
  /// validation fails, or signature verification fails.
  ///
  /// - [vcBlob] — raw VC JSON string.
  /// - [contactChannelDid] — the channel DID through which this card was
  ///   received, stored on the result for later lookup.
  Future<ReceivedRCard?> parse({
    required String vcBlob,
    String? contactChannelDid,
  }) async {
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
        !types.contains(RCardConstants.typeRCard)) {
      return null;
    }

    // Validate VC context
    final context = decoded['@context'];
    final contextList = context is List
        ? context.map((e) => e.toString()).toList()
        : <String>[];
    if (!contextList.contains(RCardConstants.contextRCard)) {
      return null;
    }

    // Parse and verify signature
    late ParsedVerifiableCredential parsedVc;
    try {
      parsedVc = UniversalParser.parse(vcBlob);
    } catch (e, st) {
      _logger.error('Failed to parse VC blob', error: e, stackTrace: st);
      return null;
    }
    final verification = await UniversalVerifier().verify(parsedVc);
    if (!verification.isValid) {
      _logger.warning('R-Card signature verification failed');
      return null;
    }

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
      version: RCardConstants.receivedRCardVersion,
      issuanceDate: issuanceDate ?? now,
      receivedAt: now,
      contactChannelDid: contactChannelDid,
    );
  }
}
