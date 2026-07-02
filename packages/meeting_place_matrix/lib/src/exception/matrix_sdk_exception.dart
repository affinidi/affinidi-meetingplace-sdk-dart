import 'package:meeting_place_core/meeting_place_core.dart'
    show MeetingPlaceCoreSDKErrorCode;

/// Base exception interface for all Matrix SDK errors.
abstract interface class MatrixSDKException implements Exception {
  String get message;
  MeetingPlaceCoreSDKErrorCode get code;
  Object? get innerException;
}
