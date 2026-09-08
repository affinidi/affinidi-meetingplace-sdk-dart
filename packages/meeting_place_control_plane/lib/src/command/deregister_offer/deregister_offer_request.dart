import '../../core/command/command.dart';
import 'deregister_offer_result.dart';

/// Model that represents the request sent for the [DeregisterOfferRequest]
/// operation.
class DeregisterOfferRequest extends DiscoveryCommand<DeregisterOfferResult> {
  /// Creates a new instance of [DeregisterOfferRequest].
  DeregisterOfferRequest({required this.offerLink, required this.mnemonic});

  /// The link of the offer to deregister.
  final String offerLink;

  /// The mnemonic identifier of the offer to deregister.
  final String mnemonic;
}
