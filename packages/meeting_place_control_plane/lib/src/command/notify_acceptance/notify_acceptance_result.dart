import 'notify_acceptance_request.dart' show NotifyAcceptanceRequest;

/// The result returned when an offer acceptance notification is sent.
/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceRequest] operation.
class NotifyAcceptanceResult {
  /// Creates a new instance of [NotifyAcceptanceResult].
  NotifyAcceptanceResult({required this.success});

  /// Whether the acceptance notification was sent successfully.
  final bool success;
}
