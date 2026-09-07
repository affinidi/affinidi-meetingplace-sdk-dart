import 'notify_acceptance.dart' show NotifyAcceptanceRequest;

/// The result returned when an offer acceptance notification is sent.
typedef NotifyAcceptanceResult = NotifyAcceptanceCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceRequest] operation.
class NotifyAcceptanceCommandOutput {
  /// Creates a new instance of [NotifyAcceptanceCommandOutput].
  NotifyAcceptanceCommandOutput({required this.success});

  /// Whether the acceptance notification was sent successfully.
  final bool success;
}
