import 'finalise_acceptance_request.dart' show FinaliseAcceptanceRequest;

/// The result returned when an offer acceptance is finalised.
/// Model that represents the output data returned from a successful execution
/// of [FinaliseAcceptanceRequest] operation.
class FinaliseAcceptanceResult {
  /// Creates a new instance of [FinaliseAcceptanceResult].
  FinaliseAcceptanceResult({
    required this.success,
    required this.notificationToken,
  });

  /// Whether the acceptance was successfully finalised.
  final bool success;

  /// The token identifying the notification channel for this acceptance.
  final String notificationToken;
}
