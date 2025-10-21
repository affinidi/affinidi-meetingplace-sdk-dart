abstract interface class SDKException {
  String get message;
  String get code;
  Object? get innerException;
}
