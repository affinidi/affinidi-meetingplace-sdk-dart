/// Model that represents the output data returned from a successful execution
/// of [FinaliseAcceptanceOutput] operation.
class FinaliseAcceptanceOutput {
  /// Creates a new instance of [FinaliseAcceptanceOutput].
  FinaliseAcceptanceOutput({
    required this.success,
    required this.notificationToken,
  });

  final bool success;
  final String notificationToken;
}
