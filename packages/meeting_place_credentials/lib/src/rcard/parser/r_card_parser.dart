import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../../shared/credential_sdk_constants.dart';
import '../model/r_card.dart';
import '../model/r_card_constants.dart';
import '../model/r_card_rejection.dart';

/// The outcome of [RCardParser.parse]: either a verified [RCard], or the
/// [RCardRejectionReason] the blob was rejected for.
sealed class RCardParseResult {
  const RCardParseResult();
}

/// `vcBlob` was a valid, fully-verified R-Card.
final class RCardParseSuccess extends RCardParseResult {
  /// Creates a successful [RCardParseResult] wrapping the parsed [rCard].
  const RCardParseSuccess(this.rCard);

  /// The parsed, verified R-Card.
  final RCard rCard;
}

/// `vcBlob` failed parsing or verification.
final class RCardParseFailure extends RCardParseResult {
  /// Creates a failed [RCardParseResult] carrying the rejection [reason].
  const RCardParseFailure(this.reason);

  /// Why the blob was rejected.
  final RCardRejectionReason reason;
}

/// Parses R-Card VC blobs and extracts verified [RCard] instances.
class RCardParser {
  /// Creates an [RCardParser], optionally injecting a [logger] and a
  /// [documentLoader].
  ///
  /// [documentLoader] is forwarded to `ssi`'s `UniversalVerifier` and used
  /// to fetch external resources (e.g. RevocationList2020 status list
  /// credentials) during verification. Production callers can leave it
  /// unset; tests can inject one to exercise revocation without a live
  /// network call.
  RCardParser({
    MeetingPlaceCoreSDKLogger? logger,
    DocumentLoader? documentLoader,
  }) : _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'RCardParser'),
       _documentLoader = documentLoader;

  final MeetingPlaceCoreSDKLogger _logger;
  final DocumentLoader? _documentLoader;

  /// Parses and verifies [vcBlob] as an R-Card credential.
  ///
  /// Returns [RCardParseSuccess] if [vcBlob] is a valid, signature-verified,
  /// non-expired, non-revoked R-Card, or [RCardParseFailure] with the reason
  /// otherwise.
  ///
  /// - [vcBlob] — raw VC JSON string.
  Future<RCardParseResult> parse({required String vcBlob}) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(vcBlob);
    } catch (_) {
      return const RCardParseFailure(RCardRejectionReason.malformedJson);
    }
    if (decoded is! Map<String, dynamic>) {
      return const RCardParseFailure(RCardRejectionReason.malformedJson);
    }

    // Validate VC type
    final types = (decoded['type'] as List?)?.map((e) => e.toString()).toSet();
    if (types == null ||
        !types.contains(CredentialsSDKConstants.typeVerifiableCredential) ||
        !types.contains(RCardConstants.typeRCard)) {
      return const RCardParseFailure(RCardRejectionReason.invalidType);
    }

    // Validate VC context
    final context = decoded['@context'];
    final contextList = context is List
        ? context.map((e) => e.toString()).toList()
        : <String>[];
    if (!contextList.contains(RCardConstants.contextRCard)) {
      return const RCardParseFailure(RCardRejectionReason.invalidContext);
    }

    // Parse and verify signature
    late ParsedVerifiableCredential parsedVc;
    try {
      parsedVc = UniversalParser.parse(vcBlob);
    } catch (e, st) {
      _logger.error('Failed to parse VC blob', error: e, stackTrace: st);
      return const RCardParseFailure(RCardRejectionReason.malformedJson);
    }

    final VerificationResult verification;
    try {
      verification = await UniversalVerifier(
        customDocumentLoader: _documentLoader,
      ).verify(parsedVc);
    } catch (e, st) {
      _logger.error('R-Card verification threw', error: e, stackTrace: st);
      return const RCardParseFailure(RCardRejectionReason.verificationError);
    }
    if (!verification.isValid) {
      _logger.warning(
        'R-Card verification failed: ${verification.errors.join('; ')}',
      );
      return const RCardParseFailure(RCardRejectionReason.verificationFailed);
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
    if (subjectDid == null || subjectDid.isEmpty) {
      return const RCardParseFailure(
        RCardRejectionReason.missingSubjectOrIssuer,
      );
    }

    final issuer = decoded['issuer'];
    final issuerDid = issuer is String
        ? issuer
        : (issuer is Map ? issuer['id']?.toString() : null);
    if (issuerDid == null || issuerDid.isEmpty) {
      return const RCardParseFailure(
        RCardRejectionReason.missingSubjectOrIssuer,
      );
    }

    final rawDate = decoded['validFrom'];
    final issuanceDate = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final now = DateTime.now().toUtc();

    return RCardParseSuccess(
      RCard(
        subjectDid: subjectDid,
        vcBlob: vcBlob,
        issuerDid: issuerDid,
        version: RCardConstants.receivedRCardVersion,
        issuanceDate: issuanceDate ?? now,
        receivedAt: now,
      ),
    );
  }
}
