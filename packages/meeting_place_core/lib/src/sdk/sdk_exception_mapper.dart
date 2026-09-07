import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';

import '../exception/sdk_exception.dart';
import '../meeting_place_core_sdk_exception.dart';
import 'sdk_error_handler.dart';

/// Converts any error raised from core-internal code into the unified
/// [MeetingPlaceCoreSDKException], preserving the specific error code from
/// internal [SDKException]s or sibling-package exceptions where available,
/// falling back to the `generic` code otherwise.
///
/// Used by stream error-forwarding paths that catch an error outside of
/// [SDKErrorHandler.handleError]'s Future-based try/catch, so both surfaces
/// of the public API give consumers the same exception contract.
MeetingPlaceCoreSDKException toCoreSdkException(Object error) {
  if (error is SDKException) {
    return MeetingPlaceCoreSDKException(
      message: error.message,
      code: error.code.value,
      innerException: error.innerException ?? error,
    );
  }
  if (error is MeetingPlaceControlPlaneSDKException) {
    return MeetingPlaceCoreSDKException(
      message: error.message,
      code: error.code,
      innerException: error.innerException,
    );
  }
  if (error is MeetingPlaceMediatorSDKException) {
    return MeetingPlaceCoreSDKException(
      message: 'Failure on MeetingPlaceCore SDK operation',
      code: error.code,
      innerException: error.innerException,
    );
  }
  return MeetingPlaceCoreSDKException(
    message: error.toString(),
    code: 'generic',
    innerException: error,
  );
}
