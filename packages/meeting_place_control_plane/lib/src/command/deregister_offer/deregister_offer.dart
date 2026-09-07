import '../../core/command/command.dart';
import 'deregister_output.dart';

/// Model that represents the request sent for the [DeregisterOfferCommand]
/// operation.
class DeregisterOfferCommand
    extends DiscoveryCommand<DeregisterOfferCommandOutput> {
  /// Creates a new instance of [DeregisterOfferCommand].
  DeregisterOfferCommand({required this.offerLink, required this.mnemonic});
  final String offerLink;
  final String mnemonic;
}
