import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../models/credential_constants.dart';
import '../models/vrc/vrc_constants.dart';

/// Parses and verifies Verifiable Relationship Credential (VRC) blobs.
class VrcParser {
  VrcParser({MeetingPlaceCoreSDKLogger? logger})
    : _logger =
          logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'VrcParser');

  final MeetingPlaceCoreSDKLogger _logger;

  /// Parses [vcBlob] and returns a [ParsedVerifiableCredential] if it is a
  /// valid, signature-verified VRC.
  ///
  /// Returns `null` if the blob is not a valid VRC, type validation fails,
  /// proof is absent, or signature verification fails.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  Future<ParsedVerifiableCredential?> parse({required String vcBlob}) async {
    if (vcBlob.isEmpty) return null;
    try {
      final decoded = jsonDecode(vcBlob) as Map<String, dynamic>;
      final types = (decoded['type'] as List?)?.cast<String>() ?? [];
      if (!types.contains(VrcConstants.typeRelationshipCredential) ||
          !types.contains(
            RelationshipCredentialConstants.typeVerifiableCredential,
          )) {
        return null;
      }
      if (!decoded.containsKey('proof')) return null;
      final parsed = UniversalParser.parse(vcBlob);
      final verification = await UniversalVerifier().verify(parsed);
      if (!verification.isValid) return null;
      return parsed;
    } catch (e, st) {
      _logger.error('Failed to parse VRC blob', error: e, stackTrace: st);
      return null;
    }
  }
}
