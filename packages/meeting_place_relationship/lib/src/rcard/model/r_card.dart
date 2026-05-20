import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'r_card_constants.dart';

/// An R-Card received from another party and ready for local storage.
///
/// This is the persistence/view model for an incoming R-Card. It stores the
/// raw VC blob alongside parsed metadata fields to avoid repeated decoding.
class RCard {
  const RCard({
    required this.subjectDid,
    required this.vcBlob,
    required this.issuerDid,
    required this.version,
    required this.issuanceDate,
    required this.receivedAt,
    this.otherPartyPermanentChannelDid,
    this.permanentChannelDid,
    this.notes,
  });

  /// Parses a [RCard] from a raw VC blob string.
  ///
  /// Returns `null` if the blob cannot be decoded or required fields
  /// are missing.
  static RCard? fromVcBlob(
    String subjectDid,
    String vcBlob, {
    MeetingPlaceCoreSDKLogger? logger,
  }) {
    final log = logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'RCard');
    try {
      final vc = LdVcDm2Suite().tryParse(vcBlob);
      if (vc == null) {
        log.warning('Could not parse VC from blob as a DM v2 credential');
        return null;
      }
      final rawJson = vc.toJson();
      final issuerRaw = rawJson['issuer'];
      final issuerDid = issuerRaw is String
          ? issuerRaw
          : (issuerRaw is Map && issuerRaw['id'] != null)
          ? issuerRaw['id'].toString()
          : null;
      if (issuerDid == null || issuerDid.isEmpty) {
        log.warning('Could not extract issuer DID from VC');
        return null;
      }
      final now = DateTime.now().toUtc();
      return RCard(
        subjectDid: subjectDid.trim(),
        vcBlob: vcBlob,
        issuerDid: issuerDid,
        version: RCardConstants.receivedRCardVersion,
        issuanceDate: vc.validFrom?.toUtc() ?? now,
        receivedAt: now,
      );
    } catch (e, st) {
      log.error('Failed to parse RCard from VC blob', error: e, stackTrace: st);
      return null;
    }
  }

  /// The DID of the credential subject (the person whose card this is).
  final String subjectDid;

  /// The raw serialised VC blob.
  final String vcBlob;

  /// The DID of the credential issuer.
  final String issuerDid;

  /// Monotonically increasing version counter used for idempotent upserts.
  final int version;

  /// The UTC timestamp from the VC's `validFrom` field.
  final DateTime issuanceDate;

  /// The UTC timestamp at which this card was received and stored locally.
  final DateTime receivedAt;

  /// The permanent channel DID of the contact who sent this R-Card, if known.
  final String? otherPartyPermanentChannelDid;

  /// Our own permanent channel DID for the channel this R-Card arrived on.
  ///
  /// Stored on receipt so consumers can correlate the card back to its
  /// originating channel without re-querying.
  final String? permanentChannelDid;

  /// Optional user notes attached to this contact.
  final String? notes;

  RCard copyWith({
    String? subjectDid,
    String? vcBlob,
    String? issuerDid,
    int? version,
    DateTime? issuanceDate,
    DateTime? receivedAt,
    String? otherPartyPermanentChannelDid,
    String? permanentChannelDid,
    String? notes,
  }) {
    return RCard(
      subjectDid: subjectDid ?? this.subjectDid,
      vcBlob: vcBlob ?? this.vcBlob,
      issuerDid: issuerDid ?? this.issuerDid,
      version: version ?? this.version,
      issuanceDate: issuanceDate ?? this.issuanceDate,
      receivedAt: receivedAt ?? this.receivedAt,
      otherPartyPermanentChannelDid:
          otherPartyPermanentChannelDid ?? this.otherPartyPermanentChannelDid,
      permanentChannelDid: permanentChannelDid ?? this.permanentChannelDid,
      notes: notes ?? this.notes,
    );
  }
}
