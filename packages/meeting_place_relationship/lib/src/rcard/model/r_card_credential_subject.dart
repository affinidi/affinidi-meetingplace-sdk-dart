import 'j_card.dart';

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
  /// Expects the credential subject to carry contact data as a jCard in the
  /// `card` property (RFC 7095), which is the format `RCardBuilder` always
  /// produces. Throws [FormatException] if `card` is absent or malformed.
  factory RCardCredentialSubject.fromJson(Map<String, dynamic> json) {
    final decoded = JCard.decode(json['card'], json['id']?.toString());
    if (decoded == null) {
      throw const FormatException(
        'Failed to decode jCard from credentialSubject.card',
      );
    }
    final flat = decoded;

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
