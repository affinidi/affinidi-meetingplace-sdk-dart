import 'register_notification.dart' show RegisterNotificationCommand;

/// Model that represents the output data returned from a successful execution
/// of [RegisterNotificationCommand] operation.
class RegisterNotificationOutput {
  /// Creates a new instance of [RegisterNotificationOutput].
  RegisterNotificationOutput({this.notificationToken, this.error});

  /// The token identifying the registered notification channel, when
  /// registration succeeds.
  final String? notificationToken;

  /// A description of the error, when registration fails.
  final String? error;
}
