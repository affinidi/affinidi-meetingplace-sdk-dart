import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';
import '../../utils/string.dart';

class ConnectionManagerException implements SDKException {
  ConnectionManagerException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory ConnectionManagerException.keyPairNotFoundError({
    required String did,
    Object? innerException,
  }) {
    return ConnectionManagerException(
      message:
          'Connection manager exception: DidManager could not be created for ${did.topAndTail()}',
      code: MeetingPlaceCoreSDKErrorCode.keyPairNotFoundError,
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
