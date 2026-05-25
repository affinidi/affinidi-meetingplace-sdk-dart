import 'package:ssi/ssi.dart';

import '../../meeting_place_relationship_sdk_exception.dart';
import 'r_card_credential_subject.dart';

/// A parsed Relationship Card (R-Card) Verifiable Credential.
///
/// Provides structured access to VC fields and a typed [credentialSubject].
class RCardVC {
  /// Creates an [RCardVC] with the given VC fields.
  const RCardVC({
    required this.credentialSubject,
    this.id,
    this.type,
    this.context,
    this.issuer,
    this.issuanceDate,
    this.proof,
  });

  /// Deserialises an [RCardVC] from a JSON map.
  ///
  /// Throws [MeetingPlaceRelationshipSDKException] if the credential subject
  /// is missing.
  factory RCardVC.fromJson(Map<String, dynamic> json) {
    // Use the SSI package to validate VC structure before extracting fields.
    final vc = VcDataModelV2.fromJson(json);
    final subject = vc.credentialSubject.firstOrNull;
    if (subject == null) {
      // ignore: lines_longer_than_80_chars
      throw MeetingPlaceRelationshipSDKException.rCardMissingCredentialSubject();
    }
    final subjectMap = Map<String, dynamic>.from(subject.toJson());
    return RCardVC(
      id: vc.id?.toString(),
      type: vc.type.toList(),
      context: json['@context'],
      issuer: json['issuer'],
      issuanceDate: vc.validFrom?.toIso8601String(),
      credentialSubject: RCardCredentialSubject.fromJson(subjectMap),
      proof: json['proof'],
    );
  }

  /// Parses an [RCardVC] directly from a raw VC blob string.
  ///
  /// Throws [MeetingPlaceRelationshipSDKException] if the credential subject
  /// is missing, or [FormatException] if the blob cannot be parsed.
  factory RCardVC.fromVcBlob(String vcBlob) {
    final vc = LdVcDm2Suite().parse(vcBlob);
    final rawJson = vc.toJson();
    final subject = vc.credentialSubject.firstOrNull;
    if (subject == null) {
      // ignore: lines_longer_than_80_chars
      throw MeetingPlaceRelationshipSDKException.rCardMissingCredentialSubject();
    }
    final subjectMap = Map<String, dynamic>.from(subject.toJson());
    return RCardVC(
      id: vc.id?.toString(),
      type: vc.type.toList(),
      context: rawJson['@context'],
      issuer: rawJson['issuer'],
      issuanceDate: vc.validFrom?.toIso8601String(),
      credentialSubject: RCardCredentialSubject.fromJson(subjectMap),
      proof: rawJson['proof'],
    );
  }

  /// Unique credential identifier, or `null` if absent.
  final String? id;

  /// W3C credential type strings.
  final List<String>? type;

  /// JSON-LD `@context` value.
  final dynamic context;

  /// Issuer DID or issuer object.
  final dynamic issuer;

  /// ISO 8601 issuance date string from `validFrom`, or `null`.
  final String? issuanceDate;

  /// Typed parsed credential subject.
  final RCardCredentialSubject credentialSubject;

  /// Raw proof object.
  final dynamic proof;

  /// Serialises this [RCardVC] to a JSON map.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (type != null) 'type': type,
    if (context != null) '@context': context,
    if (issuer != null) 'issuer': issuer,
    if (issuanceDate != null) 'issuanceDate': issuanceDate,
    'credentialSubject': credentialSubject.toJson(),
    if (proof != null) 'proof': proof,
  };
}
