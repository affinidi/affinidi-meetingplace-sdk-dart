import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class DirectConnectionServiceException implements SDKException {
  DirectConnectionServiceException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory DirectConnectionServiceException.invalidResponse({
    Object? innerException,
  }) {
    return DirectConnectionServiceException(
      message: '''Direct connection service exception: Failed to fetch the
          invitation. The provided direct connection URL is invalid or the
          server did not return a valid response.''',
      code: MeetingPlaceCoreSDKErrorCode.directConnectionInvalidData,
      innerException: innerException,
    );
  }

  factory DirectConnectionServiceException.malformedInvitation({
    Object? innerException,
  }) {
    return DirectConnectionServiceException(
      message: '''Direct connection service exception: The invitation data is
          malformed or contains invalid field types. All required fields (id,
          from, body) must be present with correct types.''',
      code: MeetingPlaceCoreSDKErrorCode.directConnectionMalformedInvitation,
      innerException: innerException,
    );
  }

  factory DirectConnectionServiceException.invalidType({
    required Uri directConnectionUri,
    required String expectedType,
    required String actualType,
    Object? innerException,
  }) {
    return DirectConnectionServiceException(
      message:
          '''Direct connection service exception: The invitation fetched from
          ${directConnectionUri.toString()} has an unexpected type.
          Expected type: $expectedType, but got: $actualType.''',
      code: MeetingPlaceCoreSDKErrorCode.directConnectionInvalidType,
      innerException: innerException,
    );
  }

  factory DirectConnectionServiceException.notFound({
    required Uri directConnectionUri,
    Object? innerException,
  }) {
    return DirectConnectionServiceException(
      message: '''Direct connection service exception: Invitation not found
          for URL: ${directConnectionUri.toString()}.''',
      code: MeetingPlaceCoreSDKErrorCode.directConnectionNotFound,
      innerException: innerException,
    );
  }

  factory DirectConnectionServiceException.networkError({
    required Uri directConnectionUri,
    Object? innerException,
  }) {
    return DirectConnectionServiceException(
      message: '''Direct connection service exception: Network error while
        fetching the invitation from URL:
        ${directConnectionUri.toString()}.''',
      code: MeetingPlaceCoreSDKErrorCode.networkError,
      innerException: innerException,
    );
  }

  factory DirectConnectionServiceException.generic({
    required Uri directConnectionUri,
    Object? innerException,
  }) {
    return DirectConnectionServiceException(
      message: '''Direct connection service exception: An error occurred
        while fetching the invitation from URL:
        ${directConnectionUri.toString()}.''',
      code: MeetingPlaceCoreSDKErrorCode.generic,
      innerException: innerException,
    );
  }

  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
