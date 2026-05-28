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

  /// Factory constructor for a VRC VC that is missing a credentialSubject.
  factory MeetingPlaceRelationshipSDKException.vrcMissingCredentialSubject({
    Object? innerException,
  }) {
    return MeetingPlaceRelationshipSDKException(
      message: 'VRC VC is missing a credentialSubject or id.',
      code: MeetingPlaceRelationshipSDKErrorCode.vrcMissingCredentialSubject,
      innerException: innerException,
    );
  }

  /// Factory constructor for when the channel or sender DID is missing when
  /// sending a VRC.
  factory MeetingPlaceRelationshipSDKException.sendVrcMissingChannel({
    required String channelDid,
    Object? innerException,
  }) {
    return MeetingPlaceRelationshipSDKException(
      message: 'Cannot send VRC: channel or sender DID missing for $channelDid',
      code: MeetingPlaceRelationshipSDKErrorCode.sendVrcMissingChannel,
      innerException: innerException,
    );
  }

  /// Factory constructor for when the channel is missing a permanentChannelDid
  /// when sending an R-Card.
  factory MeetingPlaceRelationshipSDKException.sendRCardMissingChannelDid({
    Object? innerException,
  }) {
    return MeetingPlaceRelationshipSDKException(
      message: 'Channel is missing permanentChannelDid — cannot send R-Card.',
      code: MeetingPlaceRelationshipSDKErrorCode.sendRCardMissingChannelDid,
      innerException: innerException,
    );
  }

  /// Factory constructor for an R-Card VC that is missing a credentialSubject.
  factory MeetingPlaceRelationshipSDKException.rCardMissingCredentialSubject({
    Object? innerException,
  }) {
    return MeetingPlaceRelationshipSDKException(
      message: 'R-Card VC is missing a credentialSubject.',
      code: MeetingPlaceRelationshipSDKErrorCode.rCardMissingCredentialSubject,
      innerException: innerException,
    );
  }

  /// Factory constructor for when no assertion method key is available for
  /// signing.
  factory MeetingPlaceRelationshipSDKException.signingKeyUnavailable({
    Object? innerException,
  }) {
    return MeetingPlaceRelationshipSDKException(
      message: 'DidManager has no assertionMethod keys available for signing.',
      code: MeetingPlaceRelationshipSDKErrorCode.signingKeyUnavailable,
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
