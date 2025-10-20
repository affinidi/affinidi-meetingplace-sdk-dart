enum PlatformType {
  apns('APNS'),
  apnsSandbox('APNS_SANDBOX'),
  fcm('FCM'),
  fb('FB'),
  pushNotification('PUSH_NOTIFICATION'),
  didcomm('DIDCOMM');

  const PlatformType(this.value);
  final String value;
}
