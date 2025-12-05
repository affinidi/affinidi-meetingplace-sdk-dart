import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class MessageServiceException implements SDKException {
  factory MessageServiceException.notifyChannelFailed({
    Object? innerException,
  }) {
    return MessageServiceException(
      message: 'Failed to notify channel',
      code: MeetingPlaceCoreSDKErrorCode.channelNotificationFailed,
      innerException: innerException,
    );
  }

  MessageServiceException({
    required this.message,
    required this.code,
    this.innerException,
  });

  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
