/// Model that represents the output data returned from a successful execution
/// of [RegisterNotificationOutput] operation.
class RegisterNotificationOutput {
  /// Creates a new instance of [RegisterNotificationOutput].
  RegisterNotificationOutput({this.notificationToken, this.error});
  final String? notificationToken;
  final String? error;
}
