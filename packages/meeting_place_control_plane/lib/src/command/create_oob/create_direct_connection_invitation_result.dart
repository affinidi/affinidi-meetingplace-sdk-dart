import 'create_oob_request.dart' show CreateOobRequest;

/// The result returned when a direct connection invitation is created.
/// Model that represents the output data returned from a successful execution
/// of [CreateOobRequest] operation.
class CreateDirectConnectionInvitationResult {
  /// Creates a new instance of [CreateDirectConnectionInvitationResult].
  CreateDirectConnectionInvitationResult({
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
