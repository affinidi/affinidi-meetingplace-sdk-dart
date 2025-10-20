/// Abstract interface class implemented by MediatorException class.
///
/// **Parameters:**
/// - [message]: A descriptive text explaining the nature of the exception or error.
/// - [errorCode]: An enumeration value representing the type or category of the error for easier classification.
/// - [innerException]: Holds the original exception or error object.
abstract interface class IMediatorException {
  String get message;
  String get errorCode;
  Object? get innerException;
}
