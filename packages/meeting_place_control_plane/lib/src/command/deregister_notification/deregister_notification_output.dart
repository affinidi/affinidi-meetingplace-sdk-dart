import 'deregister_notification.dart' show DeregisterNotificationCommand;
import 'deregister_notification_error_code.dart';

/// Model that represents the output data returned from a successful execution
/// of [DeregisterNotificationCommand] operation.
class DeregisterNotificationOutput {
  /// Creates a new instance of [DeregisterNotificationOutput].
  DeregisterNotificationOutput({required this.success, this.errorCode});

  final bool success;
  final DeregisterNotificationErrorCode? errorCode;
}
