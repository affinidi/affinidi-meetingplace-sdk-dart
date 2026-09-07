import '../exception/sdk_exception.dart';
import '../meeting_place_core_sdk_error_code.dart';

/// Exception class for errors thrown by `VdipClient`.
class VdipClientException implements SDKException {
  VdipClientException({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Factory constructor for creating a [VdipClientException] when a
  /// channel passed to `VdipClient.issueCredential` or
  /// `VdipClient.subscribe` is missing a DID required to address the VDIP
  /// message.
  ///
  /// Parameters:
  /// - [reason]: A description of which DID is missing and from which
  ///   operation, used to build a detailed message.
  factory VdipClientException.missingChannelDid({
    required String reason,
    Object? innerException,
  }) {
    return VdipClientException(
      message: 'VdipClient exception: $reason',
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
