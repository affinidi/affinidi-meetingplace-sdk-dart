import 'r_card.dart';

/// Reasons an incoming R-Card VC blob or attachment was rejected before
/// being surfaced as a verified [RCard].
enum RCardRejectionReason {
  /// The VC blob was not valid JSON.
  malformedJson,

  /// The VC `type` did not include both `VerifiableCredential` and
  /// `RelationshipCard`.
  invalidType,

  /// The VC `@context` did not include the R-Card schema context.
  invalidContext,

  /// Signature, expiry, or revocation verification failed.
  verificationFailed,

  /// Verification could not complete due to an unexpected error (e.g. a
  /// custom verifier throwing).
  verificationError,

  /// The VC had no usable `credentialSubject.id` or `issuer`.
  missingSubjectOrIssuer,

  /// The R-Card's `issuerDid` did not match the expected counterparty —
  /// the DIDComm message sender (VDIP path) or the channel's
  /// `otherPartyPermanentChannelDid` (channel path).
  issuerMismatch,

  /// A VDIP issued-credential message had no sender DID (`from`).
  missingSender,

  /// The DIDComm attachment envelope was malformed or not R-Card shaped.
  malformedAttachment,
}

/// The delivery path an [RCardRejection] originated from.
enum RCardRejectionSource {
  /// The VDIP (chat-time) issued-credential path.
  vdip,

  /// The DIDComm channel-attachment (OOB / inauguration) path.
  channel,
}

/// Describes one incoming R-Card that was parsed but rejected before being
/// surfaced to the app via `receivedRCards` / `receivedRCardsOnChannel`.
class RCardRejection {
  /// Creates an [RCardRejection].
  RCardRejection({
    required this.reason,
    required this.source,
    this.rCardIssuerDid,
    this.expectedDid,
    DateTime? rejectedAt,
  }) : rejectedAt = rejectedAt ?? DateTime.now().toUtc();

  /// Why the R-Card was rejected.
  final RCardRejectionReason reason;

  /// Which delivery path produced this rejection.
  final RCardRejectionSource source;

  /// The issuer DID on the rejected R-Card, if it was known at the point of
  /// rejection.
  final String? rCardIssuerDid;

  /// The DID the issuer was expected to match, if applicable to [reason]
  /// (the message sender for [RCardRejectionSource.vdip], the channel
  /// counterparty for [RCardRejectionSource.channel]).
  final String? expectedDid;

  /// When this rejection occurred.
  final DateTime rejectedAt;
}
