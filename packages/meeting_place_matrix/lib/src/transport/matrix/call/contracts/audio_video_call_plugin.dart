import '../../../../call/call_media_type.dart';
import 'audio_video_call_session.dart';
import 'incoming_audio_video_call_event.dart';

/// Interface for an audio/video calling plugin.
///
/// Provides audio and video calling capability between you and a peer
/// identified by their channel DID. The implementation resolves all
/// transport-specific details (Matrix room, LiveKit token, etc.) internally —
/// transport identifiers never appear in the consumer.
///
/// Register the implementation via `audioVideoCallPluginProvider` in
/// `main.dart`. If no plugin is registered (provider returns `null`), the UI
/// hides the call button.
///
/// Returning `false` from [isSupported] signals that the plugin is installed
/// but unavailable in the current context (e.g. DIDComm-only mode, missing
/// config, or unsupported OS).
abstract interface class AudioVideoCallPlugin {
  /// Whether this plugin can operate in the current context.
  bool get isSupported;

  /// Stream of incoming call events emitted when a peer calls you.
  ///
  /// The app shell listens to this stream and presents the incoming-call
  /// banner when an event arrives.
  Stream<IncomingAudioVideoCallEvent> get incomingCalls;

  /// Stream of incoming-call events for calls that did not connect.
  ///
  /// This includes calls cancelled by the caller before the self user
  /// answered, and calls auto-rejected as busy by this device.
  ///
  /// The app shell listens to this stream to dismiss the incoming-call banner
  /// and mark the corresponding chat item as missed when the call does not
  /// connect.
  Stream<IncomingAudioVideoCallEvent> get cancelledCalls;

  /// Starts an outbound call and returns a live [AudioVideoCallSession] handle.
  ///
  /// Also used by the recipient after [acceptCall]: the plugin detects internally
  /// that the call was already accepted and joins as recipient rather than
  /// initiating a new outbound call.
  ///
  /// Parameters:
  /// * [otherPartyChannelDid] — the peer channel DID (distinct from
  ///   their permanent identity DID).
  ///
  /// Returns an [AudioVideoCallSession] to monitor state and control the call.
  Future<AudioVideoCallSession> startCall({
    required String otherPartyChannelDid,
    required CallMediaType mediaType,
  });

  /// Marks an incoming call as accepted so [startCall] joins as recipient.
  ///
  /// Call this when the user taps Accept in the incoming-call banner, then
  /// navigate to the call screen. The screen's controller calls [startCall]
  /// to obtain the [AudioVideoCallSession] and connect.
  ///
  /// Parameters:
  /// * [callId] — the transport call session ID (from Matrix RTC),
  ///   not the caller DID.
  Future<void> acceptCall({required String callId});

  /// Declines an incoming call without answering.
  ///
  /// Parameters:
  /// * [callId] — the transport call session ID (from Matrix RTC),
  ///   not the caller DID.
  Future<void> declineCall({required String callId});

  /// Leaves the currently active call, if any, and clears the busy guard.
  ///
  /// Safe to call when no call is active. Must be called after every call ends
  /// (whether by self hangup, peer hangup, or timeout) so a subsequent
  /// incoming call is not auto-rejected.
  Future<void> leaveCurrentCall();
}
