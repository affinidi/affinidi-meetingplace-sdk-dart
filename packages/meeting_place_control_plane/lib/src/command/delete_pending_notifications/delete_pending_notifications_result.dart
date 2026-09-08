import 'delete_pending_notifications_request.dart'
    show DeletePendingNotificationsRequest;

/// The result returned when pending notifications are deleted.
/// Model that represents the output data returned from a successful execution
/// of [DeletePendingNotificationsRequest] operation.
class DeletePendingNotificationsResult {
  /// Creates a new instance of [DeletePendingNotificationsResult].
  DeletePendingNotificationsResult({this.deletedNotificationIds = const []});

  /// The identifiers of the notifications that were successfully deleted.
  final List<String> deletedNotificationIds;
}
