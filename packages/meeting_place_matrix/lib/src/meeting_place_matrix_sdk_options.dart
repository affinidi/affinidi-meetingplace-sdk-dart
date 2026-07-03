import 'package:meeting_place_core/meeting_place_core.dart';

class MeetingPlaceMatrixSdkOptions extends MeetingPlaceCoreSDKOptions {
  const MeetingPlaceMatrixSdkOptions({
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
