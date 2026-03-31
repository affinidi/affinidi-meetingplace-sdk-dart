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
  final String offerLink;
  final String offerName;
  final String? offerDescription;
  final String didcommMessage;
  final DateTime? validUntil;
  final int? maximumUsage;
  final String mediatorDid;
}
