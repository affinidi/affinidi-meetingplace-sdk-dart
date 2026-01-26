import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class EventHandlerException implements SDKException {
  EventHandlerException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory EventHandlerException.channelNotFound({
    required String did,
    Object? innerException,
  }) {
    return EventHandlerException(
      message: 'EventHandlerException: Channel for $did not found',
      code: MeetingPlaceCoreSDKErrorCode.channelNotFound,
      innerException: innerException,
    );
  }

  factory EventHandlerException.missingPermanentChannelDid({
    required String channelId,
    Object? innerException,
  }) {
    return EventHandlerException(
      message:
          '''EventHandlerException: Missing permanent channel DID for channel $channelId''',
      code: MeetingPlaceCoreSDKErrorCode.channelMissingPermanentChannelDid,
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
