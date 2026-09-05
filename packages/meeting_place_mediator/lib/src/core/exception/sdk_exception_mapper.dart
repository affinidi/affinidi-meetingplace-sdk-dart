import '../../meeting_place_mediator_sdk_error_code.dart';
import '../../meeting_place_mediator_sdk_exception.dart';
import 'i_mediator_exception.dart';

/// Converts any error raised from mediator-internal code into the unified
/// [MeetingPlaceMediatorSDKException], preserving the specific
/// [IMediatorException] code where available and falling back to
/// [MeetingPlaceMediatorSDKErrorCode.generic] otherwise.
///
/// Shared by the SDK facade's method-call wrapping and
/// MediatorStreamSubscription's stream-error wrapping so both surfaces of
/// the public API give consumers the same exception contract.
MeetingPlaceMediatorSDKException toMediatorSdkException(Object error) {
  if (error is IMediatorException) {
    return MeetingPlaceMediatorSDKException(
      message: error.message,
      code: error.code.value,
      innerException: error.innerException ?? error,
    );
  }
  return MeetingPlaceMediatorSDKException(
    message: 'Failure on Mediator SDK exception',
    code: MeetingPlaceMediatorSDKErrorCode.generic.value,
    innerException: error,
  );
}
