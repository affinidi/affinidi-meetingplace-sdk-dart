import 'package:json_annotation/json_annotation.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'j_card.dart';

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
  /// Expects a W3C Data Model v2 credential (the format produced by
  /// `RCardBuilder`).
  ///
  /// Throws a [FormatException] if the blob cannot be parsed as a DM v2
  /// credential or does not contain a recognisable jCard.
  static RCardSubject fromVcBlob(
    String vcBlob, {
    MeetingPlaceCoreSDKLogger? logger,
  }) {
    final log =
        logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'RCardSubject');
    final vc = LdVcDm2Suite().tryParse(vcBlob);
    if (vc == null) {
      const message = 'Could not parse VC from blob as a DM v2 credential';
      log.warning(message);
      throw const FormatException(message);
    }
    final subject = vc.credentialSubject.firstOrNull;
    if (subject == null) {
      const message = 'Could not extract credentialSubject from VC';
      log.warning(message);
      throw const FormatException(message);
    }
    final map = JCard.decode(subject['card'], subject.id?.toString());
    if (map == null) {
      const message = 'Could not parse jCard from credentialSubject';
      log.warning(message);
      throw const FormatException(message);
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
