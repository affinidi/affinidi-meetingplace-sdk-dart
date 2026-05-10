import 'package:ssi/ssi.dart';

import '../models/vrc/relationship_credential.dart';
import '../models/vrc/relationship_credential_subject.dart';

/// Parses and verifies Verifiable Relationship Credential (VRC) blobs.
class VrcParser {
  VrcParser._();

  /// Parses, verifies, and converts a raw VRC blob into a
  /// [RelationshipCredential].
  ///
  /// Returns `null` if the blob is not a valid, signature-verified VRC.
  ///
  /// - [vcBlob] — the raw serialised VC string.
  /// - [channelId] — the channel through which the credential was received.
  static Future<RelationshipCredential?> parse({
    required String vcBlob,
    required String channelId,
  }) async {
    final ParsedVerifiableCredential parsedVc;
    try {
      parsedVc = UniversalParser.parse(vcBlob);
    } catch (_) {
      return null;
    }

    if (!parsedVc.isCredentialVrc) return null;

    final verification = await UniversalVerifier().verify(parsedVc);
    if (!verification.isValid) return null;

    final subjectRaw =
        parsedVc.credentialSubject.firstOrNull as Map<String, dynamic>?;
    if (subjectRaw == null) return null;

    final RelationshipCredentialSubject subject;
    try {
      subject = RelationshipCredentialSubject.fromJson(subjectRaw);
    } catch (_) {
      return null;
    }

    return RelationshipCredential(
      id: parsedVc.id.toString(),
      vc: vcBlob,
      channelId: channelId,
      holderPersonaDid: subject.to.did,
      issuerPersonaDid: subject.from.did,
      issuedAt: parsedVc.validFrom ?? DateTime.now().toUtc(),
    );
  }
}
