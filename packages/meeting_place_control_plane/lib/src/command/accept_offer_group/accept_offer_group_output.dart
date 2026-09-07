import '../../../meeting_place_control_plane.dart' show AcceptOfferGroupCommand;
import '../command.dart' show AcceptOfferGroupCommand;
import 'accept_offer_group.dart' show AcceptOfferGroupCommand;

/// Model that represents the output data returned from a successful execution
/// of [AcceptOfferGroupCommand] operation.
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
