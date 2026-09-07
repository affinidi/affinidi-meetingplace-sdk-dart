import 'notify_acceptance_group.dart' show NotifyAcceptanceGroupRequest;

/// The result returned when a group acceptance notification is sent.
typedef NotifyGroupAcceptanceResult = NotifyAcceptanceGroupCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceGroupRequest] operation.
class NotifyAcceptanceGroupCommandOutput {
  /// Creates a new instance of [NotifyAcceptanceGroupCommandOutput].
  NotifyAcceptanceGroupCommandOutput({required this.success});

  /// Whether the group acceptance notification was sent successfully.
  final bool success;
}
