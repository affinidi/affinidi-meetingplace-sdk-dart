import 'deregister_offer.dart' show DeregisterOfferRequest;

/// The result returned when an offer is deregistered.
typedef DeregisterOfferResult = DeregisterOfferCommandOutput;

/// Model that represents the output data returned from a successful
/// execution of [DeregisterOfferRequest] operation.
class DeregisterOfferCommandOutput {
  /// Creates a new instance of [DeregisterOfferCommandOutput].
  DeregisterOfferCommandOutput({required this.success});

  /// Whether the offer was successfully deregistered.
  final bool success;
}
