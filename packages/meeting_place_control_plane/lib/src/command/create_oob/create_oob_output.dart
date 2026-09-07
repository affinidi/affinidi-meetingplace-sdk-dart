import 'create_oob.dart' show CreateOobCommand;

/// Model that represents the output data returned from a successful execution
/// of [CreateOobCommand] operation.
class CreateOobCommandOutput {
  /// Creates a new instance of [CreateOobCommandOutput].
  CreateOobCommandOutput({
    required this.oobId,
    required this.oobUrl,
    required this.mediatorDid,
  });

  /// The identifier of the created out-of-band invitation.
  final String oobId;

  /// The URL through which the out-of-band invitation can be retrieved.
  final String oobUrl;

  /// The DID of the mediator the invitation is published through.
  final String mediatorDid;
}
