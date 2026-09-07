/// @docImport 'meeting_place_matrix_sdk.dart';
library;

import 'package:meeting_place_core/meeting_place_core.dart';

/// [MeetingPlaceCoreSDKOptions] for a Matrix-backed [MeetingPlaceMatrixSDK],
/// currently forwarding every option to the base type without adding
/// Matrix-specific fields.
class MeetingPlaceMatrixSDKOptions extends MeetingPlaceCoreSDKOptions {
  const MeetingPlaceMatrixSDKOptions({
    super.secondsBeforeExpiryReauthenticate,
    super.debounceControlPlaneEvents,
    super.didResolverAddress,
    super.maxRetries,
    super.maxRetriesDelay,
    super.eventHandlerMessageFetchMaxRetries,
    super.eventHandlerMessageFetchMaxRetriesDelay,
    super.connectTimeout,
    super.receiveTimeout,
    super.idleTimeout,
    super.signatureScheme,
    super.expectedMessageWrappingTypes,
    super.messageTypesForSequenceTracking,
    super.onBuildAttachments,
  });
}
