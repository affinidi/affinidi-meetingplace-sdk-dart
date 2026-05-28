import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../../shared/credential_builder.dart';
import 'vrc_party.dart';

/// The credential subject of a Verifiable Relationship Credential (VRC).
///
/// Describes the two parties in the relationship: [from] (the issuer's
/// party) and [to] (the counterpart's party).
class VrcCredentialSubject {
  /// Creates a [VrcCredentialSubject] with the given [from] and [to] parties.
  const VrcCredentialSubject({required this.from, required this.to});

  /// Deserialises a [VrcCredentialSubject] from a JSON map.
  factory VrcCredentialSubject.fromJson(Map<String, dynamic> json) =>
      VrcCredentialSubject(
        from: VrcParty.fromJson(json['from'] as Map<String, dynamic>),
        to: VrcParty.fromJson(json['to'] as Map<String, dynamic>),
      );

  /// The party issuing the VRC.
  final VrcParty from;

  /// The counterpart in the relationship.
  final VrcParty to;

  /// Parses a [VrcCredentialSubject] directly from a raw VC blob string.
  ///
  /// Expects a W3C Data Model v2 credential (the format produced by
  /// [CredentialBuilder.buildVrc]).
  ///
  /// Throws a [FormatException] if the blob cannot be parsed as a DM v2
  /// credential or does not contain a recognisable VRC subject.
  static VrcCredentialSubject fromVcBlob(
    String vcBlob, {
    MeetingPlaceCoreSDKLogger? logger,
  }) {
    final log =
        logger ??
        DefaultMeetingPlaceCoreSDKLogger(className: 'VrcCredentialSubject');
    final vc = LdVcDm2Suite().tryParse(vcBlob);
    if (vc == null) {
      const message = 'Could not parse VC from blob as a DM v2 credential';
      log.warning(message);
      throw const FormatException(message);
    }
    final subject = vc.credentialSubject.firstOrNull as Map<String, dynamic>?;
    if (subject == null) {
      const message = 'Could not extract credentialSubject from VC';
      log.warning(message);
      throw const FormatException(message);
    }
    try {
      return VrcCredentialSubject.fromJson(subject);
    } catch (error, stackTrace) {
      const message =
          'VRC credentialSubject is missing required from/to fields';
      log.error(message, error: error, stackTrace: stackTrace);
      throw FormatException('$message: $error');
    }
  }

  /// Serialises this [VrcCredentialSubject] to a JSON map.
  Map<String, dynamic> toJson() => {
    'from': {'did': from.did, 'name': from.name},
    'to': {'did': to.did, 'name': to.name},
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VrcCredentialSubject && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'VrcCredentialSubject(from: $from, to: $to)';
}
