import 'package:ssi/ssi.dart';

import '../credential_constants.dart';
import '../r_card/r_card_constants.dart';
import 'relationship_credential_subject.dart';
import 'vrc_constants.dart';

/// A parsed and stored Verifiable Relationship Credential (VRC).
class RelationshipCredential {
  const RelationshipCredential({
    required this.id,
    required this.vc,
    required this.channelId,
    required this.holderPersonaDid,
    required this.issuerPersonaDid,
    required this.issuedAt,
    this.verifiedAt,
  });

  final String id;

  /// The raw serialised VC blob.
  final String vc;

  /// The DIDComm channel ID through which this credential was exchanged.
  final String channelId;

  /// The DID of the credential holder (the `to` party in the subject).
  final String holderPersonaDid;

  /// The DID of the credential issuer (the `from` party in the subject).
  final String issuerPersonaDid;

  final DateTime issuedAt;

  /// When this credential was last verified, or `null` if unverified.
  final DateTime? verifiedAt;

  RelationshipCredential copyWith({
    String? id,
    String? vc,
    String? channelId,
    String? holderPersonaDid,
    String? issuerPersonaDid,
    DateTime? issuedAt,
    DateTime? verifiedAt,
  }) {
    return RelationshipCredential(
      id: id ?? this.id,
      vc: vc ?? this.vc,
      channelId: channelId ?? this.channelId,
      holderPersonaDid: holderPersonaDid ?? this.holderPersonaDid,
      issuerPersonaDid: issuerPersonaDid ?? this.issuerPersonaDid,
      issuedAt: issuedAt ?? this.issuedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

/// Extension helpers on [ParsedVerifiableCredential] for the relationship
/// domain.
extension ParsedVcRelationshipExtensions on ParsedVerifiableCredential {
  /// Converts a parsed VC to a [RelationshipCredential] value object.
  RelationshipCredential toRelationshipCredential({
    required String channelId,
    DateTime? verifiedAt,
  }) {
    final subjectJson = credentialSubject.firstOrNull as Map<String, dynamic>?;
    final subject = RelationshipCredentialSubject.fromJson(subjectJson ?? {});

    return RelationshipCredential(
      id: id.toString(),
      vc: serialized as String,
      channelId: channelId,
      holderPersonaDid: subject.to.did,
      issuerPersonaDid: subject.from.did,
      issuedAt: validFrom ?? DateTime.now(),
      verifiedAt: verifiedAt,
    );
  }

  /// Returns `true` when this VC is an R-Card credential.
  bool get isCredentialRCard {
    return type.contains(
          RelationshipCredentialConstants.typeVerifiableCredential,
        ) &&
        type.contains(RCardConstants.typeRCard);
  }

  /// Returns `true` when this VC is a Verifiable Relationship Credential.
  bool get isCredentialVrc {
    return type.contains(
          RelationshipCredentialConstants.typeVerifiableCredential,
        ) &&
        type.contains(VrcConstants.typeRelationshipCredential);
  }
}
