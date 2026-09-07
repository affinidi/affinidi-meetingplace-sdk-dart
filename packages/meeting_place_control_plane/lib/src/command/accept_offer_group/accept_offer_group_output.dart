import '../../../meeting_place_control_plane.dart' show AcceptOfferGroupRequest;
import '../command.dart' show AcceptOfferGroupRequest;
import 'accept_offer_group.dart' show AcceptOfferGroupRequest;

/// The result returned when a group offer is accepted.
typedef AcceptOfferGroupResult = AcceptOfferGroupCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [AcceptOfferGroupRequest] operation.
class AcceptOfferGroupCommandOutput {
  /// Creates a new instance of [AcceptOfferGroupCommandOutput].
  AcceptOfferGroupCommandOutput({
    required this.offerLink,
    required this.didcommMessage,
    required this.validUntil,
    required this.mediatorDid,
  });

  /// The link of the group offer that was accepted.
  final String offerLink;

  /// The DIDComm message to send in order to complete the acceptance flow.
  final String didcommMessage;

  /// The date and time after which the offer is no longer valid, if set.
  final DateTime? validUntil;

  /// The DID of the mediator the offer was published through.
  final String mediatorDid;
}
