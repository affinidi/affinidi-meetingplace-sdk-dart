/// Model that represents the output data returned from a successful execution
/// of [CreateOobCommandOutput] operation.
class CreateOobCommandOutput {
  /// Creates a new instance of [CreateOobCommandOutput].
  CreateOobCommandOutput({
    required this.oobId,
    required this.oobUrl,
    required this.mediatorDid,
  });
  final String oobId;
  final String oobUrl;
  final String mediatorDid;
}
