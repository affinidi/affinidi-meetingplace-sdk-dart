import '../../../meeting_place_control_plane.dart' show AcceptOfferCommand;
import '../command.dart' show AcceptOfferCommand;
import 'accept_offer.dart' show AcceptOfferCommand;

/// Model that represents the output data returned from a successful execution
/// of [AcceptOfferCommand] operation.
class AcceptOfferCommandOutput {
  /// Creates a new instance of [AcceptOfferCommandOutput].
  AcceptOfferCommandOutput({
    required this.offerLink,
    required this.offerName,
    required this.offerDescription,
    required this.didcommMessage,
    required this.validUntil,
    required this.maximumUsage,
    required this.mediatorDid,
  });

  /// The link of the offer that was accepted.
  final String offerLink;

  /// The name of the offer that was accepted.
  final String offerName;

  /// The description of the offer that was accepted, if any.
  final String? offerDescription;

  /// The DIDComm message to send in order to complete the acceptance flow.
  final String didcommMessage;

  /// The date and time after which the offer is no longer valid, if set.
  final DateTime? validUntil;

  /// The maximum number of times the offer may be accepted, if limited.
  final int? maximumUsage;

  /// The DID of the mediator the offer was published through.
  final String mediatorDid;
}
