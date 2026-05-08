import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

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
  static RCardSubject? fromVcBlob(
    String vcBlob, {
    MeetingPlaceCoreSDKLogger? logger,
  }) {
    final log =
        logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'RCardSubject');
    final subject = _extractCredentialSubjectMapFromVcBlob(vcBlob);
    if (subject == null) {
      log.warning('Could not extract credentialSubject from VC blob');
      return null;
    }
    final map = _jCardToFlatMap(subject['card'], subject['id']?.toString());
    if (map == null) {
      log.warning('Could not parse jCard from credentialSubject');
      return null;
    }
    return RCardSubject.fromJson(map);
  }

  /// Returns the full display name, trimming any leading/trailing whitespace.
  String get name => [firstName, lastName]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ')
      .trim();
}

Map<String, dynamic>? _extractCredentialSubjectMapFromVcBlob(String vcBlob) {
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
  final props = card[1];
  if (props is! List) return null;
  return {
    'id': id,
    for (final p in props)
      if (p is List && p.length >= 4 && p[0] != null)
        p[0].toString(): _trim(p[3]),
  };
}

String? _trim(dynamic v) {
  final s = v?.toString().trim();
  return s != null && s.isNotEmpty ? s : null;
}
