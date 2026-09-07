import 'delete_pending_notifications.dart'
    show DeletePendingNotificationsRequest;

/// The result returned when pending notifications are deleted.
typedef DeletePendingNotificationsResult =
    DeletePendingNotificationsCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [DeletePendingNotificationsRequest] operation.
class DeletePendingNotificationsCommandOutput {
  /// Creates a new instance of [DeletePendingNotificationsCommandOutput].
  DeletePendingNotificationsCommandOutput({
    this.deletedNotificationIds = const [],
  });

  /// The identifiers of the notifications that were successfully deleted.
  final List<String> deletedNotificationIds;
}
