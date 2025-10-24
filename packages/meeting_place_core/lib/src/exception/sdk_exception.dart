import '../meeting_place_core_sdk_error_code.dart';

abstract interface class SDKException {
  String get message;
  MeetingPlaceCoreSDKErrorCode get code;
  Object? get innerException;
}
