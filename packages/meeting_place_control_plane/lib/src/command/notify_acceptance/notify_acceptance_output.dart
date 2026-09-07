import 'notify_acceptance.dart' show NotifyAcceptanceCommand;

/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceCommand] operation.
class NotifyAcceptanceCommandOutput {
  /// Creates a new instance of [NotifyAcceptanceCommandOutput].
  NotifyAcceptanceCommandOutput({required this.success});
  final bool success;
}
