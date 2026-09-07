import 'get_oob.dart' show GetOobCommand;

/// The result returned when a direct connection invitation is retrieved.
typedef GetDirectConnectionInvitationResult = GetOobCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [GetOobCommand] operation.
class GetOobCommandOutput {
  /// Creates a new instance of [GetOobCommandOutput].
  GetOobCommandOutput({
    required this.invitationMessage,
    required this.mediatorDid,
  });

  /// The retrieved out-of-band invitation message.
  final String invitationMessage;

  /// The DID of the mediator the invitation is published through.
  final String mediatorDid;
}
