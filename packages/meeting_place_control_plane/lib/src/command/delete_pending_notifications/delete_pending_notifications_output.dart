import 'delete_pending_notifications.dart'
    show DeletePendingNotificationsCommand;

/// Model that represents the output data returned from a successful execution
/// of [DeletePendingNotificationsCommand] operation.
class DeletePendingNotificationsCommandOutput {
  /// Creates a new instance of [DeletePendingNotificationsCommandOutput].
  DeletePendingNotificationsCommandOutput({
    this.deletedNotificationIds = const [],
  });
  final List<String> deletedNotificationIds;
}
