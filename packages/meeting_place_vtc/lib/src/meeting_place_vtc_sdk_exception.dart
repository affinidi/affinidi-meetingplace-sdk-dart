import 'meeting_place_vtc_sdk_error_code.dart';

/// Exception thrown by the Meeting Place VTC SDK.
///
/// Messages never contain keys, signatures, or document contents so that the
/// exception is safe to log.
class MeetingPlaceVtcSDKException implements Exception {
  /// Creates a [MeetingPlaceVtcSDKException] instance.
  MeetingPlaceVtcSDKException({
    required this.message,
    required this.code,
    this.innerException,
    this.refusalCode,
  });

  /// A Trust Task document is missing a required field or has a wrong type.
  factory MeetingPlaceVtcSDKException.invalidDocument(String reason) {
    return MeetingPlaceVtcSDKException(
      message: 'Invalid Trust Task document: $reason',
      code: MeetingPlaceVtcSDKErrorCode.invalidDocument,
    );
  }

  /// A document proof is missing, malformed, or does not verify.
  factory MeetingPlaceVtcSDKException.invalidProof(
    String reason, {
    Object? innerException,
  }) {
    return MeetingPlaceVtcSDKException(
      message: 'Invalid document proof: $reason',
      code: MeetingPlaceVtcSDKErrorCode.invalidProof,
      innerException: innerException,
    );
  }

  /// The community's DID could not be resolved or verified.
  factory MeetingPlaceVtcSDKException.didResolutionFailed({
    Object? innerException,
  }) {
    return MeetingPlaceVtcSDKException(
      message: 'The community DID could not be resolved.',
      code: MeetingPlaceVtcSDKErrorCode.didResolutionFailed,
      innerException: innerException,
    );
  }

  /// The community's DID document lacks a usable service of [serviceType].
  factory MeetingPlaceVtcSDKException.signInNotOffered(String serviceType) {
    return MeetingPlaceVtcSDKException(
      message: 'The community publishes no usable $serviceType service.',
      code: MeetingPlaceVtcSDKErrorCode.signInNotOffered,
    );
  }

  /// The service could not be reached or did not answer with a document.
  factory MeetingPlaceVtcSDKException.transportFailed(
    String reason, {
    Object? innerException,
  }) {
    return MeetingPlaceVtcSDKException(
      message: 'Trust Task request failed: $reason',
      code: MeetingPlaceVtcSDKErrorCode.transportFailed,
      innerException: innerException,
    );
  }

  /// The service refused the task with [refusalCode], e.g.
  /// `auth/oob/claim:alreadyClaimed`.
  factory MeetingPlaceVtcSDKException.refused(String refusalCode) {
    return MeetingPlaceVtcSDKException(
      message: 'Trust Task refused: $refusalCode',
      code: MeetingPlaceVtcSDKErrorCode.refused,
      refusalCode: refusalCode,
    );
  }

  /// Human-readable description of the failure.
  final String message;

  /// Machine-readable failure code.
  final MeetingPlaceVtcSDKErrorCode code;

  /// Underlying error, if any.
  final Object? innerException;

  /// Full refusal code of a Trust Task error, when [code] is
  /// [MeetingPlaceVtcSDKErrorCode.refused].
  final String? refusalCode;

  @override
  String toString() => 'MeetingPlaceVtcSDKException(${code.value}): $message';
}
