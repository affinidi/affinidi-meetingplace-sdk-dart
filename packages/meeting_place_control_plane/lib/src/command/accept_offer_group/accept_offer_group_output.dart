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
  final String offerLink;
  final String didcommMessage;
  final DateTime? validUntil;
  final String mediatorDid;
}
