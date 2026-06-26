import '../models/audio_video_call_state.dart';

/// A live handle to an active or connecting audio/video call.
///
/// Returned by `AudioVideoCallPlugin.startCall` and
/// `AudioVideoCallPlugin.acceptCall`. Holds the call for its full lifetime:
/// from transport connection to hang-up. Dispose via [hangUp]; the plugin
/// disposes the underlying resources when [hangUp] completes.
abstract interface class AudioVideoCallSession {
  /// Live stream of [AudioVideoCallState] for this call.
  ///
  /// Emits immediately with the current state and continues on every change.
  /// The caller is responsible for cancelling any subscription.
  Stream<AudioVideoCallState> get state;

  /// Enables or disables the local microphone.
  Future<void> setMicrophoneEnabled(bool enabled);

  /// Enables or disables the local camera.
  Future<void> setCameraEnabled(bool enabled);

  /// Switches between front and rear camera.
  Future<void> switchCamera();

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece.
  Future<void> setSpeakerphoneEnabled(bool enabled);

  /// Leaves the call and releases all associated resources.
  Future<void> hangUp();
}
