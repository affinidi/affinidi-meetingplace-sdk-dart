import 'deregister_notification.dart' show DeregisterNotificationCommand;
import 'deregister_notification_error_code.dart';

/// The result returned when a notification channel is deregistered.
typedef DeregisterNotificationResult = DeregisterNotificationOutput;

/// Model that represents the output data returned from a successful execution
/// of [DeregisterNotificationCommand] operation.
class DeregisterNotificationOutput {
  /// Creates a new instance of [DeregisterNotificationOutput].
  DeregisterNotificationOutput({required this.success, this.errorCode});

  /// Whether the notification token was successfully deregistered.
  final bool success;

  /// The reason [success] is `false`, if the deregistration did not succeed.
  final DeregisterNotificationErrorCode? errorCode;
}
