import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant;

import '../models/call_e2ee_state.dart';

/// Callback invoked when a participant's E2EE state changes.
typedef OnCallE2EEStateChanged =
    void Function(String participantId, CallE2EEState state);

/// Callback invoked when a remote participant disconnects.
typedef OnParticipantDisconnected = void Function(String participantId);

/// Abstracts all LiveKit room operations required by `AudioVideoCallService`.
///
/// Implementations live in the Flutter consumer layer and depend on
/// livekit_client. The SDK layer depends only on this abstraction, keeping
/// meeting_place_matrix_livekit free of Flutter and livekit_client.
abstract interface class LiveKitRoom {
  /// Stable identity of this client's participant in the room, or `null`
  /// when not connected.
  String? get ownParticipantId;

  /// Snapshot of all current participants mapped to domain objects.
  List<AudioVideoCallParticipant> get participants;

  /// Sets the shared E2EE key for this call session.
  ///
  /// Must be called before [connect] so that the implementation can wire the
  /// key into the room's FrameCryptor before media flows.
  Future<void> setSharedKey(String key);

  /// Ratchets the E2EE key for [participantId].
  Future<void> ratchetKey(String participantId, int keyIndex);

  /// Connects to the LiveKit SFU at [url] with [token].
  Future<void> connect({
    required String url,
    required String token,
    Map<String, String> participantIdToDid = const {},
    OnCallE2EEStateChanged? onE2EEStateChanged,
    OnParticipantDisconnected? onParticipantDisconnected,
    void Function()? onParticipantsChanged,
  });

  /// Disconnects from the room and releases all resources.
  Future<void> disconnect();

  /// Enables or disables the local microphone.
  Future<void> setMicrophoneEnabled(bool enabled);

  /// Enables or disables the local camera.
  Future<void> setCameraEnabled(bool enabled);

  /// Switches between front and rear camera.
  Future<void> switchCamera();

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece.
  Future<void> setSpeakerphoneEnabled(bool enabled);

  /// Forces the SFU to emit a fresh keyframe for [participantId]'s video.
  Future<void> forceRemoteKeyframe(String participantId);
}
