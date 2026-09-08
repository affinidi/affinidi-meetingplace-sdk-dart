import '../../core/offer_type.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import '../../core/protocol/message/oob_invitation_message.dart';
import '../../core/protocol/transport.dart';
import 'query_offer_request.dart' show QueryOfferRequest;

/// The result returned when finding an offer by its mnemonic phrase.
/// Base class for the possible outcomes of a [QueryOfferRequest] operation.
abstract class FindOfferByMnemonicResult {}

/// Model that represents the output data returned from a successful execution
/// of [QueryOfferRequest] operation.
class SuccessFindOfferByMnemonicResult extends FindOfferByMnemonicResult {
  /// Creates a new instance of [SuccessFindOfferByMnemonicResult].
  SuccessFindOfferByMnemonicResult({
    required this.offerName,
    required this.offerLink,
    required this.offerDescription,
    required this.type,
    required this.mnemonic,
    required this.contactCard,
    required this.expiresAt,
    required this.maximumUsage,
    required this.mediatorDid,
    required this.status,
    required this.didcommMessage,
    required this.transport,
    this.groupId,
    this.score,
  });

  /// The human-readable name of the offer.
  final String offerName;

  /// The shareable link to the offer.
  final String offerLink;

  /// A description of the offer.
  final String offerDescription;

  /// The type of offer that was queried.
  final OfferType type;

  /// The mnemonic phrase identifying the offer.
  final String mnemonic;

  /// The contact card associated with the offer.
  final ContactCard contactCard;

  /// The point in time after which the offer expires, when set.
  final DateTime? expiresAt;

  /// The maximum number of times the offer can be accepted, when set.
  final int? maximumUsage;

  /// The DID of the mediator handling the offer.
  final String mediatorDid;

  /// The current status of the offer as reported by the API server.
  final String status;

  /// The out-of-band DIDComm invitation message embedded in the offer.
  final OobInvitationMessage didcommMessage;

  /// The unique identifier of the group offer, when the offer is a group
  /// invitation.
  final String? groupId;

  /// The score assigned to the offer, when provided.
  final int? score;

  /// Transport selected by the publisher.
  final OfferTransport transport;

  /// Whether the offer is a direct invitation.
  bool get isInvitation => type == OfferType.invitation;

  /// Whether the offer is a group invitation.
  bool get isGroupInvitation => type == OfferType.groupInvitation;

  /// Whether the offer is an outreach invitation.
  bool get isOutreachInvitation => type == OfferType.outreachInvitation;
}

/// Model that represents the output of a [QueryOfferRequest] operation when
/// the queried offer does not exist.
class NullFindOfferByMnemonicResult extends FindOfferByMnemonicResult {}

/// Model that represents the output of a [QueryOfferRequest] operation when
/// the offer's query limit has been exceeded.
class LimitExceededFindOfferByMnemonicResult
    extends FindOfferByMnemonicResult {}

/// Model that represents the output of a [QueryOfferRequest] operation when
/// the queried offer has expired.
class ExpiredFindOfferByMnemonicResult extends FindOfferByMnemonicResult {}
