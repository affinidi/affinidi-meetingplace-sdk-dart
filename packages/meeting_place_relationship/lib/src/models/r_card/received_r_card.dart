import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../credential_constants.dart';

/// An R-Card received from another party and ready for local storage.
///
/// This is the persistence/view model for an incoming R-Card. It stores the
/// raw VC blob alongside parsed metadata fields to avoid repeated decoding.
class ReceivedRCard {
  const ReceivedRCard({
    required this.subjectDid,
    required this.vcBlob,
    required this.issuerDid,
    required this.version,
    required this.issuanceDate,
    required this.receivedAt,
    this.contactChannelDid,
    this.threadId,
    this.notes,
  });

  /// Parses a [ReceivedRCard] from a raw VC blob string.
  ///
  /// Returns `null` if the blob cannot be decoded or required fields
  /// are missing.
  static ReceivedRCard? fromVcBlob(
    String subjectDid,
    String vcBlob, {
    MeetingPlaceCoreSDKLogger? logger,
  }) {
    final log =
        logger ?? DefaultMeetingPlaceCoreSDKLogger(className: 'ReceivedRCard');
    try {
      final decoded = jsonDecode(vcBlob) as Map<String, dynamic>?;
      if (decoded == null) return null;
      final issuer = decoded['issuer'];
      final issuerDid = issuer is String
          ? issuer
          : (issuer is Map && issuer['id'] != null)
          ? issuer['id'].toString()
          : null;
      if (issuerDid == null || issuerDid.isEmpty) return null;
      final raw = decoded['validFrom'];
      final issuanceDate = raw is String ? DateTime.tryParse(raw) : null;
      final now = DateTime.now().toUtc();
      return ReceivedRCard(
        subjectDid: subjectDid.trim(),
        vcBlob: vcBlob,
        issuerDid: issuerDid,
        version: RelationshipCredentialConstants.receivedRCardVersion,
        issuanceDate: issuanceDate ?? now,
        receivedAt: now,
      );
    } catch (e, st) {
      log.error(
        'Failed to parse ReceivedRCard from VC blob',
        error: e,
        stackTrace: st,
      );
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

  final DateTime issuanceDate;
  final DateTime receivedAt;

  /// The DIDComm channel DID through which this card was received, if known.
  final String? contactChannelDid;

  /// The DIDComm thread ID of the exchange that delivered this card, if known.
  final String? threadId;

  /// Optional user notes attached to this contact.
  final String? notes;

  ReceivedRCard copyWith({
    String? subjectDid,
    String? vcBlob,
    String? issuerDid,
    int? version,
    DateTime? issuanceDate,
    DateTime? receivedAt,
    String? contactChannelDid,
    String? threadId,
    String? notes,
  }) {
    return ReceivedRCard(
      subjectDid: subjectDid ?? this.subjectDid,
      vcBlob: vcBlob ?? this.vcBlob,
      issuerDid: issuerDid ?? this.issuerDid,
      version: version ?? this.version,
      issuanceDate: issuanceDate ?? this.issuanceDate,
      receivedAt: receivedAt ?? this.receivedAt,
      contactChannelDid: contactChannelDid ?? this.contactChannelDid,
      threadId: threadId ?? this.threadId,
      notes: notes ?? this.notes,
    );
  }
}
