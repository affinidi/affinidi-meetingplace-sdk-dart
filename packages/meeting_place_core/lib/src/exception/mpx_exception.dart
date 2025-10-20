abstract interface class MpxException {
  String get message;
  String get errorCode;
  Object? get innerException;
}
