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
  /// Uses the SSI package to decode and validate the VC structure before
  /// extracting the jCard credential subject. Returns `null` if the blob
  /// cannot be parsed as a signed DM v2 credential or does not contain a
  /// recognisable jCard.
  static RCardSubject? fromVcBlob(
    String vcBlob, {
    MeetingPlaceCoreSDKLogger? logger,
  }) {
    final log =
        logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'RCardSubject');
    final vc = LdVcDm2Suite().tryParse(vcBlob);
    if (vc == null) {
      log.warning('Could not parse VC from blob as a signed DM v2 credential');
      return null;
    }
    final subject = vc.credentialSubject.firstOrNull;
    if (subject == null) {
      log.warning('Could not extract credentialSubject from VC');
      return null;
    }
    final map = JCard.decode(subject['card'], subject.id?.toString());
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
