import 'package:ssi/ssi.dart';

import '../../meeting_place_relationship_sdk_exception.dart';
import 'r_card_credential_subject.dart';

/// A parsed Relationship Card (R-Card) Verifiable Credential.
///
/// Provides structured access to VC fields and a typed [credentialSubject].
class RCardVC {
  const RCardVC({
    required this.credentialSubject,
    this.id,
    this.type,
    this.context,
    this.issuer,
    this.issuanceDate,
    this.proof,
  });

  factory RCardVC.fromJson(Map<String, dynamic> json) {
    // Use the SSI package to validate VC structure before extracting fields.
    final vc = VcDataModelV2.fromJson(json);
    final subject = vc.credentialSubject.firstOrNull;
    if (subject == null) {
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

  factory RCardVC.fromVcBlob(String vcBlob) {
    final vc = LdVcDm2Suite().parse(vcBlob);
    final rawJson = vc.toJson();
    final subject = vc.credentialSubject.firstOrNull;
    if (subject == null) {
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

  final String? id;
  final List<String>? type;
  final dynamic context;
  final dynamic issuer;
  final String? issuanceDate;
  final RCardCredentialSubject credentialSubject;
  final dynamic proof;

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
