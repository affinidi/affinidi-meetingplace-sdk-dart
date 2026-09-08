import 'get_oob_request.dart' show GetOobRequest;

/// The result returned when a direct connection invitation is retrieved.
/// Model that represents the output data returned from a successful execution
/// of [GetOobRequest] operation.
class GetDirectConnectionInvitationResult {
  /// Creates a new instance of [GetDirectConnectionInvitationResult].
  GetDirectConnectionInvitationResult({
    required this.invitationMessage,
    required this.mediatorDid,
  });

  /// The retrieved out-of-band invitation message.
  final String invitationMessage;

  /// The DID of the mediator the invitation is published through.
  final String mediatorDid;
}
