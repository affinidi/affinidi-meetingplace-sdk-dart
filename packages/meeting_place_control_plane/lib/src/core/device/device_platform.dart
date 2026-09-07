/// The channel through which a device receives notifications.
enum PlatformType {
  /// Notifications are delivered via a push notification service.
  pushNotification('PUSH_NOTIFICATION'),

  /// Notifications are delivered via a DIDComm message.
  didcomm('DIDCOMM');

  const PlatformType(this.value);

  /// The wire string representation of this platform type.
  final String value;
}
