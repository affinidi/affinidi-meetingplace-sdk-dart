import 'deregister_offer.dart' show DeregisterOfferCommand;

/// Model that represents the output data returned from a successful
/// execution of [DeregisterOfferCommand] operation.
class DeregisterOfferCommandOutput {
  /// Creates a new instance of [DeregisterOfferCommandOutput].
  DeregisterOfferCommandOutput({required this.success});
  final bool success;
}
