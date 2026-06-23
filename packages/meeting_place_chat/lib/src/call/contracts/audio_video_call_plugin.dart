import 'package:meeting_place_core/meeting_place_core.dart' show CallMediaType;

import './audio_video_call_session.dart';
import 'incoming_audio_video_call_event.dart';

/// Interface for an audio/video calling plugin.
///
/// Provides audio and video calling capability between you and another party
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

  /// Stream of incoming call events emitted when the other party calls you.
  ///
  /// The app shell listens to this stream and presents the incoming-call
  /// banner when an event arrives.
  Stream<IncomingAudioVideoCallEvent> get incomingCalls;

  /// Stream of call IDs for incoming calls that were cancelled by the caller
  /// before the local user answered.
  ///
  /// The app shell listens to this stream to dismiss the incoming-call banner
  /// and mark the corresponding chat item as missed when the remote party
  /// hangs up before the call is accepted.
  Stream<String> get cancelledCalls;

  /// Starts an outbound call and returns a live [AudioVideoCallSession] handle.
  ///
  /// Also used by the callee after [acceptCall]: the plugin detects internally
  /// that the call was already accepted and joins as callee rather than
  /// initiating a new outbound call.
  ///
  /// Parameters:
  /// * [otherPartyChannelDid] — the other party's channel DID (distinct from
  ///   their permanent identity DID).
  ///
  /// Returns an [AudioVideoCallSession] to monitor state and control the call.
  Future<AudioVideoCallSession> startCall({
    required String otherPartyChannelDid,
    required CallMediaType mediaType,
  });

  /// Marks an incoming call as accepted so [startCall] joins as callee.
  ///
  /// Call this when the user taps Accept in the incoming-call banner, then
  /// navigate to the call screen. The screen's controller calls [startCall]
  /// to obtain the [AudioVideoCallSession] and connect.
  ///
  /// Parameters:
  /// * [callId] — must match [IncomingAudioVideoCallEvent.callId].
  Future<void> acceptCall({required String callId});

  /// Declines an incoming call without answering.
  ///
  /// Parameters:
  /// * [callId] — must match [IncomingAudioVideoCallEvent.callId].
  Future<void> declineCall({required String callId});
}
