abstract interface class ControlPlaneException {
  String get message;
  String get errorCode;
  Object? get innerException;
}
