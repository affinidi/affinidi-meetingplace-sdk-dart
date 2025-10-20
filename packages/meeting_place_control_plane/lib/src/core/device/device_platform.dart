enum PlatformType {
  pushNotification('PUSH_NOTIFICATION'),
  didcomm('DIDCOMM');

  const PlatformType(this.value);
  final String value;
}
