import 'finalise_acceptance.dart' show FinaliseAcceptanceCommand;

/// The result returned when an offer acceptance is finalised.
typedef FinaliseAcceptanceResult = FinaliseAcceptanceOutput;

/// Model that represents the output data returned from a successful execution
/// of [FinaliseAcceptanceCommand] operation.
class FinaliseAcceptanceOutput {
  /// Creates a new instance of [FinaliseAcceptanceOutput].
  FinaliseAcceptanceOutput({
    required this.success,
    required this.notificationToken,
  });

  /// Whether the acceptance was successfully finalised.
  final bool success;

  /// The token identifying the notification channel for this acceptance.
  final String notificationToken;
}
