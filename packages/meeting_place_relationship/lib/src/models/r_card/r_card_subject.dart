import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'r_card_subject.g.dart';

@JsonSerializable()
class RCardSubject {
  const RCardSubject({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.company,
    this.position,
    this.website,
    this.social,
    this.profilePic,
  });

  factory RCardSubject.fromJson(Map<String, dynamic> json) =>
      _$RCardSubjectFromJson(json);

  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? position;
  final String? website;
  final String? social;
  final String? profilePic;

  Map<String, dynamic> toJson() => _$RCardSubjectToJson(this);

  /// Parses an [RCardSubject] directly from a raw VC blob string.
  ///
  /// Returns `null` if the blob cannot be decoded or does not contain a
  /// recognisable jCard credential subject.
  static RCardSubject? fromVcBlob(String vcBlob) {
    final subject = extractCredentialSubjectMapFromVcBlob(vcBlob);
    if (subject == null) return null;
    final map = _jCardToFlatMap(subject['card'], subject['id']?.toString());
    return map != null ? RCardSubject.fromJson(map) : null;
  }

  /// Returns the full display name, trimming any leading/trailing whitespace.
  String get name => [firstName, lastName]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ')
      .trim();
}

/// Extracts the `credentialSubject` map from a raw VC blob JSON string.
///
/// Returns `null` if the blob cannot be decoded or the subject is absent.
Map<String, dynamic>? extractCredentialSubjectMapFromVcBlob(String vcBlob) {
  try {
    final sub = (jsonDecode(vcBlob) as Map?)?['credentialSubject'];
    return sub is Map
        ? Map<String, dynamic>.from(sub)
        : (sub is List && sub.isNotEmpty && sub.first is Map)
            ? Map<String, dynamic>.from(sub.first as Map)
            : null;
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _jCardToFlatMap(dynamic card, String? id) {
  if (card is! List || card.length < 2 || card[0] != 'vcard') return null;
  final props = card[1] as List<dynamic>? ?? [];
  return {
    'id': id,
    for (final p in props)
      if (p is List && p.length >= 4 && p[0] != null)
        p[0] as String: _trim(p[3]),
  };
}

String? _trim(dynamic v) {
  final s = v?.toString().trim();
  return s != null && s.isNotEmpty ? s : null;
}
