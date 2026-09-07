import 'accept_offer_group_request.dart' show AcceptOfferGroupRequest;

/// The result returned when a group offer is accepted.
/// Model that represents the output data returned from a successful execution
/// of [AcceptOfferGroupRequest] operation.
class AcceptOfferGroupResult {
  /// Creates a new instance of [AcceptOfferGroupResult].
  AcceptOfferGroupResult({
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
