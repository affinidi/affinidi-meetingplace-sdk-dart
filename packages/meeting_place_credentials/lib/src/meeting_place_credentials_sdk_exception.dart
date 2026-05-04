import 'meeting_place_credentials_sdk.dart';
import 'meeting_place_credentials_sdk_error_code.dart';

/// Exception thrown when an error occurs in [MeetingPlaceCredentialsSDK].
class MeetingPlaceCredentialsSDKException implements Exception {
  /// Creates a [MeetingPlaceCredentialsSDKException] instance.
  MeetingPlaceCredentialsSDKException({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Factory constructor for a VRC credential that could not be parsed.
  factory MeetingPlaceCredentialsSDKException.vrcInvalidCredential({
    Object? innerException,
  }) {
    return MeetingPlaceCredentialsSDKException(
      message: 'Could not parse vcBlob as a valid VRC credential.',
      code: MeetingPlaceCredentialsSDKErrorCode.vrcInvalidCredential,
      innerException: innerException,
    );
  }

  /// Factory constructor for a VRC VC that is missing a credentialSubject.
  factory MeetingPlaceCredentialsSDKException.vrcMissingCredentialSubject({
    Object? innerException,
  }) {
    return MeetingPlaceCredentialsSDKException(
      message: 'VRC VC is missing a credentialSubject or id.',
      code: MeetingPlaceCredentialsSDKErrorCode.vrcMissingCredentialSubject,
      innerException: innerException,
    );
  }

  /// Factory constructor for when the channel or sender DID is missing when
  /// sending a VRC.
  factory MeetingPlaceCredentialsSDKException.sendVrcMissingChannel({
    required String channelDid,
    Object? innerException,
  }) {
    return MeetingPlaceCredentialsSDKException(
      message: 'Cannot send VRC: channel or sender DID missing for $channelDid',
      code: MeetingPlaceCredentialsSDKErrorCode.sendVrcMissingChannel,
      innerException: innerException,
    );
  }

  /// Factory constructor for when the channel is missing a permanentChannelDid
  /// when sending an R-Card.
  factory MeetingPlaceCredentialsSDKException.sendRCardMissingChannelDid({
    Object? innerException,
  }) {
    return MeetingPlaceCredentialsSDKException(
      message: 'Channel is missing permanentChannelDid — cannot send R-Card.',
      code: MeetingPlaceCredentialsSDKErrorCode.sendRCardMissingChannelDid,
      innerException: innerException,
    );
  }

  /// Factory constructor for an R-Card VC that is missing a credentialSubject.
  factory MeetingPlaceCredentialsSDKException.rCardMissingCredentialSubject({
    Object? innerException,
  }) {
    return MeetingPlaceCredentialsSDKException(
      message: 'R-Card VC is missing a credentialSubject.',
      code: MeetingPlaceCredentialsSDKErrorCode.rCardMissingCredentialSubject,
      innerException: innerException,
    );
  }

  /// Factory constructor for when no assertion method key is available for
  /// signing.
  factory MeetingPlaceCredentialsSDKException.signingKeyUnavailable({
    Object? innerException,
  }) {
    return MeetingPlaceCredentialsSDKException(
      message: 'DidManager has no assertionMethod keys available for signing.',
      code: MeetingPlaceCredentialsSDKErrorCode.signingKeyUnavailable,
      innerException: innerException,
    );
  }

  /// The descriptive message for the exception.
  final String message;

  /// The error code categorising this exception.
  final MeetingPlaceCredentialsSDKErrorCode code;

  /// The original exception that caused this error, if any.
  final Object? innerException;

  @override
  String toString() =>
      'MeetingPlaceCredentialsSDKException: $message '
      '(code: ${code.value})';
}
