import 'dart:convert';

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
    final subject = json['credentialSubject'];
    Map<String, dynamic>? subjectMap;

    if (subject is List && subject.isNotEmpty && subject.first is Map) {
      subjectMap = Map<String, dynamic>.from(subject.first as Map);
    } else if (subject is Map) {
      subjectMap = Map<String, dynamic>.from(subject);
    } else {
      throw const FormatException('Invalid credentialSubject format');
    }

    return RCardVC(
      id: json['id'] as String?,
      type: (json['type'] as List?)?.map((e) => e as String).toList(),
      context: json['@context'],
      issuer: json['issuer'],
      issuanceDate: json['issuanceDate'] as String?,
      credentialSubject: RCardCredentialSubject.fromJson(subjectMap),
      proof: json['proof'],
    );
  }

  factory RCardVC.fromVcBlob(String vcBlob) {
    final decoded = jsonDecode(vcBlob);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid VC blob format');
    }
    return RCardVC.fromJson(decoded);
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

  factory RCardCredentialSubject.fromJson(Map<String, dynamic> json) {
    const knownKeys = {'id', 'name', 'profilePic', 'email', 'phone', 'address'};
    final additionalFields = Map<String, dynamic>.from(json)
      ..removeWhere((key, _) => knownKeys.contains(key));

    return RCardCredentialSubject(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim(),
      profilePic: (json['profilePic'] as String?)?.trim(),
      email: (json['email'] as String?)?.trim(),
      phone: (json['phone'] as String?)?.trim(),
      address: (json['address'] as String?)?.trim(),
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
