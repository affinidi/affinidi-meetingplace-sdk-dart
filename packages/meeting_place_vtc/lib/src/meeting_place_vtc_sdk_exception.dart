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

  /// Human-readable description of the failure.
  final String message;

  /// Machine-readable failure code.
  final MeetingPlaceVtcSDKErrorCode code;

  /// Underlying error, if any.
  final Object? innerException;

  @override
  String toString() => 'MeetingPlaceVtcSDKException(${code.value}): $message';
}
