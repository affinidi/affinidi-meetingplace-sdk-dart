import 'package:ssi/ssi.dart';

import 'j_card.dart';

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
      throw const FormatException('Missing credentialSubject');
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
      throw const FormatException('Missing credentialSubject');
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

/// The structured credential subject of an R-Card VC.
class RCardCredentialSubject {
  const RCardCredentialSubject({
    required this.id,
    this.name,
    this.profilePic,
    this.email,
    this.phone,
    this.address,
    this.additionalFields,
  });

  /// Parses an [RCardCredentialSubject] from a credential subject JSON map.
  ///
  /// Handles both the current jCard-encoded format (where contact data is
  /// stored as a `card` property following RFC 7095) and the legacy flat-field
  /// format for backward compatibility.
  factory RCardCredentialSubject.fromJson(Map<String, dynamic> json) {
    // Decode jCard if present; fall back to treating the map as flat fields.
    final Map<String, dynamic> flat;
    if (json['card'] != null) {
      final decoded = JCard.decode(json['card'], json['id']?.toString());
      if (decoded == null) {
        throw const FormatException(
          'Failed to decode jCard from credentialSubject.card',
        );
      }
      flat = decoded;
    } else {
      flat = json;
    }

    final firstName = (flat['firstName'] as String?)?.trim();
    final lastName = (flat['lastName'] as String?)?.trim();
    final derivedName = [
      firstName,
      lastName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();

    const knownKeys = {
      'id',
      'firstName',
      'lastName',
      'name',
      'profilePic',
      'email',
      'phone',
      'address',
    };
    final additionalFields = Map<String, dynamic>.from(flat)
      ..removeWhere((key, _) => knownKeys.contains(key));

    return RCardCredentialSubject(
      id: (flat['id'] as String?)?.trim() ?? '',
      name: derivedName.isNotEmpty
          ? derivedName
          : (flat['name'] as String?)?.trim(),
      profilePic: (flat['profilePic'] as String?)?.trim(),
      email: (flat['email'] as String?)?.trim(),
      phone: (flat['phone'] as String?)?.trim(),
      address: (flat['address'] as String?)?.trim(),
      additionalFields: additionalFields.isEmpty ? null : additionalFields,
    );
  }

  final String id;
  final String? name;
  final String? profilePic;
  final String? email;
  final String? phone;
  final String? address;

  /// Any non-standard fields present in the credential subject.
  final Map<String, dynamic>? additionalFields;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (name != null) 'name': name,
    if (profilePic != null) 'profilePic': profilePic,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (additionalFields != null) ...additionalFields!,
  };
}
