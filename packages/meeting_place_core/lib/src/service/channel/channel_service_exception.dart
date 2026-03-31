import '../../entity/entity.dart';
import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';
import '../../utils/string.dart';
import 'channel_service.dart' show ChannelService;

/// Exception class for errors thrown by [ChannelService].
class ChannelServiceException implements SDKException {
  /// Creates a new instance of [ChannelServiceException].
  ///
  /// Parameters:
  /// - [message]: A descriptive message about the exception.
  /// - [code]: A specific error code from [MeetingPlaceCoreSDKErrorCode] that
  ///   categorizes the error.
  /// - [innerException]: An optional inner exception that caused this error.
  ChannelServiceException({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Factory constructor for creating a [ChannelServiceException] when a
  /// channel is not found.
  ///
  /// Parameters:
  /// - [did]: The DID of the channel that was not found, used to create a
  ///   detailed message.
  /// - [innerException]: An optional inner exception that caused this error.
  ///
  /// Returns a [ChannelServiceException] with a message indicating that the
  /// channel was not found for the given DID. The message includes a truncated
  /// version of the DID.
  factory ChannelServiceException.channelNotFound({
    required String did,
    Object? innerException,
  }) {
    return ChannelServiceException(
      message:
          'Channel service exception: Channel not found for '
          '${did.topAndTail()}',
      code: MeetingPlaceCoreSDKErrorCode.channelNotFound,
      innerException: innerException,
    );
  }

  /// Factory constructor for creating a [ChannelServiceException] when a
  /// channel has an invalid status. Includes the expected and actual status in
  /// the message.
  ///
  /// Parameters:
  /// - [expected]: The expected [ChannelStatus].
  /// - [actual]: The actual [ChannelStatus] that was found.
  /// - [innerException]: An optional inner exception that caused this error.
  ///
  /// Returns a [ChannelServiceException] with a detailed message about the
  /// invalid status.
  factory ChannelServiceException.invalidChannelStatus({
    required ChannelStatus expected,
    required ChannelStatus actual,
    Object? innerException,
  }) {
    return ChannelServiceException(
      message: '''Channel service exception: Invalid channel status.
          Expected: $expected, Actual: $actual''',
      code: MeetingPlaceCoreSDKErrorCode.channelInvalidStatus,
      innerException: innerException,
    );
  }

  /// Factory constructor for creating a [ChannelServiceException] when a
  /// channel has an invalid type. Includes the expected and actual type in the
  /// message.
  ///
  /// Parameters:
  /// - [expected]: The expected list of possible [ChannelType]s.
  /// - [actual]: The actual [ChannelType] that was found.
  /// - [innerException]: An optional inner exception that caused this error.
  ///
  /// Returns a [ChannelServiceException] with a detailed message about the
  /// invalid type.
  factory ChannelServiceException.invalidChannelType({
    required List<ChannelType> expected,
    required ChannelType actual,
    Object? innerException,
  }) {
    return ChannelServiceException(
      message: '''Channel service exception: Invalid channel type.
          Expected: $expected, Actual: $actual''',
      code: MeetingPlaceCoreSDKErrorCode.channelInvalidType,
      innerException: innerException,
    );
  }

  /// Factory constructor for creating a [ChannelServiceException] when an
  /// action is not allowed on a channel. Includes the action in the message.
  ///
  /// Parameters:
  ///
  factory ChannelServiceException.actionNotAllowed({
    required String action,
    Object? innerException,
  }) {
    return ChannelServiceException(
      message: '''Channel service exception: Action not allowed: $action.''',
      code: MeetingPlaceCoreSDKErrorCode.channelActionNotAllowed,
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
