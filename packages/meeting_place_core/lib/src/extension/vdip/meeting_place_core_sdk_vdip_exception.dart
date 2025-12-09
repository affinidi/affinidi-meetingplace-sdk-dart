import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class MeetingPlaceCoreSDKVdipException implements SDKException {
  MeetingPlaceCoreSDKVdipException({
    required this.message,
    required this.code,
    required this.innerException,
  });

  factory MeetingPlaceCoreSDKVdipException.missingChannelDids({
    String? permanentChannelDid,
    String? otherPartyPermanentChannelDid,
    Object? innerException,
  }) {
    return MeetingPlaceCoreSDKVdipException(
      message:
          'Cannot perform VDIP operation: channel is missing required DIDs '
          '(permanentChannelDid: ${permanentChannelDid != null ? "present" : "null"}, '
          'otherPartyPermanentChannelDid: ${otherPartyPermanentChannelDid != null ? "present" : "null"})',
      code: MeetingPlaceCoreSDKErrorCode.generic, // TODO
      innerException: ArgumentError(
        'Both permanentChannelDid and otherPartyPermanentChannelDid must be non-null',
      ),
    );
  }

  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
