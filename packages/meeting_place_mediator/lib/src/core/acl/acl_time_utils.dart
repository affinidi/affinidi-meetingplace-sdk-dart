DateTime getCreatedTime() {
  return DateTime.now().toUtc();
}

DateTime getExpiresTime(int expiresInSeconds) {
  return getCreatedTime().add(Duration(seconds: expiresInSeconds));
}
