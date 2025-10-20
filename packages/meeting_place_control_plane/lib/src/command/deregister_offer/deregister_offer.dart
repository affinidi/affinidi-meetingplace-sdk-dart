import '../../core/command/command.dart';
import 'deregister_output.dart';

/// Model that represents the output data returned from a successful execution
/// of [DeregisterOfferCommand] operation.
class DeregisterOfferCommand
    extends DiscoveryCommand<DeregisterOfferCommandOutput> {
  /// Creates a new instance of [DeregisterOfferCommand].
  DeregisterOfferCommand({required this.offerLink, required this.mnemonic});
  final String offerLink;
  final String mnemonic;
}
