import 'package:json_annotation/json_annotation.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'j_card.dart';

part 'r_card_subject.g.dart';

/// Parsed contact fields from an R-Card Verifiable Credential.
///
/// All fields are optional because a contact card may be partially filled.
/// Use `RCardSubject.fromVcBlob` to deserialise from a raw VC blob, or
/// `RCardVCardExtension.toVCard` to serialise to a vCard 3.0 string.
@JsonSerializable()
class RCardSubject {
  /// Creates an [RCardSubject] with the given optional contact fields.
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

  /// Deserialises an [RCardSubject] from a JSON map.
  factory RCardSubject.fromJson(Map<String, dynamic> json) =>
      _$RCardSubjectFromJson(json);

  /// Optional DID of the credential subject.
  final String? id;

  /// Given name.
  final String? firstName;

  /// Family name.
  final String? lastName;

  /// Email address.
  final String? email;

  /// Phone number.
  final String? phone;

  /// Organisation name.
  final String? company;

  /// Job title.
  final String? position;

  /// Personal or professional website URL.
  final String? website;

  /// Social profile URL or handle.
  final String? social;

  /// Profile picture URL or base64-encoded data URI.
  final String? profilePic;

  /// Serialises this [RCardSubject] to a JSON map.
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
