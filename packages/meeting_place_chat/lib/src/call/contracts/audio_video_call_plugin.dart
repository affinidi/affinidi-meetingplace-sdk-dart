import './audio_video_call_session.dart';
import 'incoming_audio_video_call_event.dart';

/// Interface for an audio/video calling plugin.
///
/// Implement this to provide calling capability for a given contact.
/// The implementation resolves all transport-specific details (Matrix room ID,
/// LiveKit token, etc.) from the app-level `contactId` or `callId` internally.
/// Transport identifiers never appear in the consumer.
///
/// Register the implementation via `audioVideoCallPluginProvider` in
/// `main.dart`. If no plugin is registered (provider returns `null`),
/// the UI hides the call button.
///
/// Returning `false` from [isSupported] signals that the plugin is installed
/// but unavailable in the current context (e.g. DIDComm-only mode, missing
/// config, or unsupported OS).
abstract interface class AudioVideoCallPlugin {
  /// Whether this plugin can operate in the current context.
  bool get isSupported;

  /// Stream of incoming call events from remote parties.
  ///
  /// The app shell listens to this stream and presents the incoming call
  /// banner when an event arrives.
  Stream<IncomingAudioVideoCallEvent> get incomingCalls;

  /// Starts an outbound call for the contact identified by [contactId] and
  /// returns a live [AudioVideoCallSession] handle.
  ///
  /// Also used by the callee after [acceptCall]: the plugin knows internally
  /// that the call for [contactId] was already accepted and joins as callee
  /// rather than initiating a new outbound call.
  Future<AudioVideoCallSession> startCall({required String contactId});

  /// Marks an incoming call as accepted.
  ///
  /// Call this when the user taps Accept in the incoming-call banner, then
  /// navigate to the call screen. The screen's controller calls [startCall]
  /// to obtain the [AudioVideoCallSession] and connect.
  ///
  /// [callId] must match the value from the corresponding
  /// [IncomingAudioVideoCallEvent].
  Future<void> acceptCall({required String callId});

  /// Declines an incoming call identified by [callId] without answering.
  Future<void> declineCall({required String callId});
}
