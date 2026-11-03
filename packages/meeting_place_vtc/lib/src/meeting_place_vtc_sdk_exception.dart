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
    this.errorPayload,
    this.httpStatus,
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

  /// A DID, of a community or a VTA, could not be resolved or verified.
  factory MeetingPlaceVtcSDKException.didResolutionFailed({
    Object? innerException,
  }) {
    return MeetingPlaceVtcSDKException(
      message: 'The DID could not be resolved.',
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

  /// The member's VTA has no DID hosting server, so it cannot publish a
  /// persona that a community can resolve.
  factory MeetingPlaceVtcSDKException.didHostingMissing() {
    return MeetingPlaceVtcSDKException(
      message: 'The VTA has no DID hosting server.',
      code: MeetingPlaceVtcSDKErrorCode.didHostingMissing,
    );
  }

  /// The service could not be reached or did not answer with a document.
  factory MeetingPlaceVtcSDKException.transportFailed(
    String reason, {
    Object? innerException,
    int? httpStatus,
  }) {
    return MeetingPlaceVtcSDKException(
      message: 'Trust Task request failed: $reason',
      code: MeetingPlaceVtcSDKErrorCode.transportFailed,
      innerException: innerException,
      httpStatus: httpStatus,
    );
  }

  /// The service refused the task with [refusalCode], e.g.
  /// `auth/oob/claim:alreadyClaimed`, answering with [httpStatus].
  factory MeetingPlaceVtcSDKException.refused(
    String refusalCode, {
    Map<String, dynamic>? errorPayload,
    int? httpStatus,
  }) {
    return MeetingPlaceVtcSDKException(
      message: 'Trust Task refused: $refusalCode',
      code: MeetingPlaceVtcSDKErrorCode.refused,
      refusalCode: refusalCode,
      errorPayload: errorPayload,
      httpStatus: httpStatus,
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

  /// Payload of the Trust Task error document, when refused. Not part of
  /// [toString], so it is never logged by accident.
  final Map<String, dynamic>? errorPayload;

  /// HTTP status of a failed request without a Trust Task answer.
  final int? httpStatus;

  /// Includes the underlying error, such as why a DID did not resolve.
  /// Neither carries keys or signatures.
  @override
  String toString() {
    final cause = innerException == null ? '' : ' Caused by: $innerException';
    return 'MeetingPlaceVtcSDKException(${code.value}): $message$cause';
  }
}
