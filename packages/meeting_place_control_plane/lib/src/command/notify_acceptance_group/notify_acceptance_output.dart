import '../notify_acceptance/notify_acceptance_output.dart';

/// Model that represents the output data returned from a successful execution
/// of [NotifyAcceptanceCommandOutput] operation.
class NotifyAcceptanceGroupCommandOutput {
  /// Creates a new instance of [NotifyAcceptanceGroupCommandOutput].
  NotifyAcceptanceGroupCommandOutput({required this.success});
  final bool success;
}
