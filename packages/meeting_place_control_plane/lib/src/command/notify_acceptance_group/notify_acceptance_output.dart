import 'notify_acceptance_group.dart' show NotifyAcceptanceGroupCommand;

/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceGroupCommand] operation.
class NotifyAcceptanceGroupCommandOutput {
  /// Creates a new instance of [NotifyAcceptanceGroupCommandOutput].
  NotifyAcceptanceGroupCommandOutput({required this.success});

  /// Whether the group acceptance notification was sent successfully.
  final bool success;
}
