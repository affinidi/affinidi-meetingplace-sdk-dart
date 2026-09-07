import 'deregister_notification_error_code.dart';
import 'deregister_notification_request.dart'
    show DeregisterNotificationRequest;

/// The result returned when a notification channel is deregistered.
/// Model that represents the output data returned from a successful execution
/// of [DeregisterNotificationRequest] operation.
class DeregisterNotificationResult {
  /// Creates a new instance of [DeregisterNotificationResult].
  DeregisterNotificationResult({required this.success, this.errorCode});

  /// Whether the notification token was successfully deregistered.
  final bool success;

  /// The reason [success] is `false`, if the deregistration did not succeed.
  final DeregisterNotificationErrorCode? errorCode;
}
