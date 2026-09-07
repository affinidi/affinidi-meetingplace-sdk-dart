import 'register_notification_request.dart' show RegisterNotificationRequest;

/// The result returned when a notification channel is registered.
/// Model that represents the output data returned from a successful execution
/// of [RegisterNotificationRequest] operation.
class RegisterNotificationResult {
  /// Creates a new instance of [RegisterNotificationResult].
  RegisterNotificationResult({this.notificationToken, this.error});

  /// The token identifying the registered notification channel, when
  /// registration succeeds.
  final String? notificationToken;

  /// A description of the error, when registration fails.
  final String? error;
}
