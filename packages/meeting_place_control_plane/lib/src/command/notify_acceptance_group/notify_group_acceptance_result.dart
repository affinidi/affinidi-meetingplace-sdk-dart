import 'notify_acceptance_group_request.dart' show NotifyAcceptanceGroupRequest;

/// The result returned when a group acceptance notification is sent.
/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceGroupRequest] operation.
class NotifyGroupAcceptanceResult {
  /// Creates a new instance of [NotifyGroupAcceptanceResult].
  NotifyGroupAcceptanceResult({required this.success});

  /// Whether the group acceptance notification was sent successfully.
  final bool success;
}
