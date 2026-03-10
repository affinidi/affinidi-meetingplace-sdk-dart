import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class OobServiceException implements SDKException {
  OobServiceException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory OobServiceException.invalidOobResponse({Object? innerException}) {
    return OobServiceException(
      message: '''OOB Service exception: Failed to fetch OOB invitation. The
          provided OOB URL is invalid or the server did not return a valid
          response.''',
      code: MeetingPlaceCoreSDKErrorCode.oobInvalidData,
      innerException: innerException,
    );
  }

  factory OobServiceException.invalidOobType({
    required Uri oobUri,
    required String expectedType,
    required String actualType,
    Object? innerException,
  }) {
    return OobServiceException(
      message:
          '''OOB Service exception: The OOB invitation fetched from
          ${oobUri.toString()} has an unexpected type.
          Expected type: $expectedType, but got: $actualType.''',
      code: MeetingPlaceCoreSDKErrorCode.oobInvalidType,
      innerException: innerException,
    );
  }

  factory OobServiceException.notFound({
    required Uri oobUri,
    Object? innerException,
  }) {
    return OobServiceException(
      message: '''OOB Service exception: OOB invitation not found for URL:
          ${oobUri.toString()}.''',
      code: MeetingPlaceCoreSDKErrorCode.oobNotFound,
      innerException: innerException,
    );
  }

  factory OobServiceException.networkError({
    required Uri oobUri,
    Object? innerException,
  }) {
    return OobServiceException(
      message: '''OOB Service exception: Network error while fetching OOB
        invitation from URL: ${oobUri.toString()}.''',
      code: MeetingPlaceCoreSDKErrorCode.networkError,
      innerException: innerException,
    );
  }

  factory OobServiceException.generic({
    required Uri oobUri,
    Object? innerException,
  }) {
    return OobServiceException(
      message: '''OOB Service exception: An error occurred while fetching OOB
        invitation from URL: ${oobUri.toString()}.''',
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
