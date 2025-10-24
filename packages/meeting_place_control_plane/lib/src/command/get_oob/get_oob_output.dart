/// Model that represents the output data returned from a successful execution
/// of [GetOobCommandOutput] operation.
class GetOobCommandOutput {
  /// Creates a new instance of [GetOobCommandOutput].
  GetOobCommandOutput({
    required this.invitationMessage,
    required this.mediatorDid,
  });
  final String invitationMessage;
  final String mediatorDid;
}
