import 'meeting_place_relationship_sdk.dart';
import 'meeting_place_relationship_sdk_error_code.dart';

/// Exception thrown when an error occurs in [MeetingPlaceRelationshipSDK].
class MeetingPlaceRelationshipSDKException implements Exception {
  /// Creates a [MeetingPlaceRelationshipSDKException] instance.
  MeetingPlaceRelationshipSDKException({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Factory constructor for a VRC credential that could not be parsed.
  factory MeetingPlaceRelationshipSDKException.vrcInvalidCredential({
    Object? innerException,
  }) {
    return MeetingPlaceRelationshipSDKException(
      message: 'Could not parse vcBlob as a valid VRC credential.',
      code: MeetingPlaceRelationshipSDKErrorCode.vrcInvalidCredential,
      innerException: innerException,
    );
  }

  /// The descriptive message for the exception.
  final String message;

  /// The error code categorising this exception.
  final MeetingPlaceRelationshipSDKErrorCode code;

  /// The original exception that caused this error, if any.
  final Object? innerException;

  @override
  String toString() =>
      'MeetingPlaceRelationshipSDKException: $message '
      '(code: ${code.value})';
}
