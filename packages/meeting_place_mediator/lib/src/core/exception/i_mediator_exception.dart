import '../../meeting_place_mediator_sdk_error_code.dart';

/// Abstract interface class implemented by MediatorException class.
///
/// **Parameters:**
/// - [message]: A descriptive text explaining the nature of the exception or error.
/// - [errorCode]: An enumeration value representing the type or category of the error for easier classification.
/// - [innerException]: Holds the original exception or error object.
abstract interface class IMediatorException {
  String get message;
  MeetingPlaceMediatorSDKErrorCode get code;
  Object? get innerException;
}
