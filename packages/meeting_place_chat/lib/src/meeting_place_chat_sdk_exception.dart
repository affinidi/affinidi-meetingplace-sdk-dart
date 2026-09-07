import 'meeting_place_chat_sdk_error_code.dart';

/// The unified exception type thrown by every operational public method on
/// `MeetingPlaceChatSDK` and its implementations.
class MeetingPlaceChatSDKException implements Exception {
  /// Creates a [MeetingPlaceChatSDKException] instance.
  MeetingPlaceChatSDKException({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Factory constructor for a chat operation that could not resolve the
  /// underlying channel for the chat's other party.
  factory MeetingPlaceChatSDKException.channelNotFound({
    required String otherPartyDid,
    Object? innerException,
  }) {
    return MeetingPlaceChatSDKException(
      message: 'Channel with peer DID $otherPartyDid not found.',
      code: MeetingPlaceChatSDKErrorCode.channelNotFound,
      innerException: innerException,
    );
  }

  /// Factory constructor for a `senderDid` that does not belong to either
  /// participant of the chat.
  factory MeetingPlaceChatSDKException.invalidParticipant({
    required String senderDid,
    Object? innerException,
  }) {
    return MeetingPlaceChatSDKException(
      message: 'senderDid $senderDid is not a participant of this chat.',
      code: MeetingPlaceChatSDKErrorCode.invalidParticipant,
      innerException: innerException,
    );
  }

  /// Factory constructor for an operation that requires the local contact
  /// card but none is set.
  factory MeetingPlaceChatSDKException.missingContactCard({
    Object? innerException,
  }) {
    return MeetingPlaceChatSDKException(
      message: 'ContactCard missing for contact details update.',
      code: MeetingPlaceChatSDKErrorCode.missingContactCard,
      innerException: innerException,
    );
  }

  /// Factory constructor for an operation this chat implementation or
  /// transport does not support.
  factory MeetingPlaceChatSDKException.operationNotSupported({
    required String operation,
    Object? innerException,
  }) {
    return MeetingPlaceChatSDKException(
      message: '$operation is not supported by this chat implementation.',
      code: MeetingPlaceChatSDKErrorCode.operationNotSupported,
      innerException: innerException,
    );
  }

  /// The exception message.
  final String message;

  /// The code of the exception.
  final MeetingPlaceChatSDKErrorCode code;

  /// The original exception that caused this error, if any.
  final Object? innerException;

  @override
  String toString() => '$message (code: ${code.value})';
}
