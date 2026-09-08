import 'deregister_offer_request.dart' show DeregisterOfferRequest;

/// The result returned when an offer is deregistered.
/// Model that represents the output data returned from a successful
/// execution of [DeregisterOfferRequest] operation.
class DeregisterOfferResult {
  /// Creates a new instance of [DeregisterOfferResult].
  DeregisterOfferResult({required this.success});

  /// Whether the offer was successfully deregistered.
  final bool success;
}
