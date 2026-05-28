import 'package:ssi/ssi.dart';

import '../../meeting_place_credentials_sdk_exception.dart';
import 'vrc_credential_subject.dart';

/// A parsed and verified VRC suitable for in-memory use and persistence.
class Vrc {
  /// Creates a [Vrc] with all required domain fields.
  const Vrc({
    required this.id,
    required this.vcBlob,
    required this.referenceId,
    required this.holderDid,
    required this.issuerDid,
    required this.issuedAt,
    this.verifiedAt,
    this.receivedAt,
    this.credentialFormat,
  });

  /// Unique credential identifier (from the VC `id` field).
  final String id;

  /// Raw serialised VC JSON as received or produced by a credential builder.
  final String vcBlob;

  /// App-defined reference identifier used to correlate this VRC with its
  /// exchange context (e.g. a channel DID or proposal ID).
  final String referenceId;

  /// DID of the credential holder, taken from the `to` party of the
  /// credential subject.
  final String holderDid;

  /// DID of the credential issuer, taken from the `from` party of the
  /// credential subject.
  final String issuerDid;

  /// UTC timestamp from the VC `validFrom` field.
  final DateTime issuedAt;

  /// UTC timestamp when the credential signature was verified, or `null` if
  /// verification has not yet taken place.
  final DateTime? verifiedAt;

  /// UTC timestamp when this VRC was received and stored locally, or `null`
  /// if not yet persisted.
  final DateTime? receivedAt;

  /// Serialisation format identifier (e.g. `w3c/v2`), or `null` if the
  /// format could not be determined from the issuance message.
  final String? credentialFormat;

  /// Returns a copy of this [Vrc] with the specified fields replaced.
  Vrc copyWith({
    String? id,
    String? vcBlob,
    String? referenceId,
    String? holderDid,
    String? issuerDid,
    DateTime? issuedAt,
    DateTime? verifiedAt,
    DateTime? receivedAt,
    String? credentialFormat,
  }) {
    return Vrc(
      id: id ?? this.id,
      vcBlob: vcBlob ?? this.vcBlob,
      referenceId: referenceId ?? this.referenceId,
      holderDid: holderDid ?? this.holderDid,
      issuerDid: issuerDid ?? this.issuerDid,
      issuedAt: issuedAt ?? this.issuedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      credentialFormat: credentialFormat ?? this.credentialFormat,
    );
  }
}

/// Extension on [ParsedVerifiableCredential] for mapping a verified VRC into
/// the SDK's canonical [Vrc] domain model.
extension ParsedVerifiableCredentialVrcExtension on ParsedVerifiableCredential {
  /// Maps a parsed VRC into the SDK's canonical representation.
  Vrc toVrc({
    required String referenceId,
    DateTime? verifiedAt,
    DateTime? receivedAt,
    String? credentialFormat,
  }) {
    final subjectJson = credentialSubject.firstOrNull as Map<String, dynamic>?;
    if (subjectJson == null) {
      throw MeetingPlaceCredentialsSDKException.vrcMissingCredentialSubject();
    }
    final subject = VrcCredentialSubject.fromJson(subjectJson);
    final credentialId = id;
    if (credentialId == null) {
      throw MeetingPlaceCredentialsSDKException.vrcMissingCredentialSubject();
    }

    return Vrc(
      id: credentialId.toString(),
      vcBlob: serialized as String,
      referenceId: referenceId,
      holderDid: subject.to.did,
      issuerDid: subject.from.did,
      issuedAt: validFrom ?? DateTime.now().toUtc(),
      verifiedAt: verifiedAt,
      receivedAt: receivedAt,
      credentialFormat: credentialFormat,
    );
  }
}
