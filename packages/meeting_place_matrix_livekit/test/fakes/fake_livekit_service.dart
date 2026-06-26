import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant;
import 'package:meeting_place_matrix_livekit/src/interfaces/livekit_room.dart';

/// Test double for [LiveKitRoom] that records calls and returns
/// configurable stub data. Replaces the old `FakeLivekitService`.
class FakeLiveKitRoom implements LiveKitRoom {
  final List<bool> micCalls = [];
  final List<bool> cameraCalls = [];
  final List<bool> speakerCalls = [];
  int switchCameraCalls = 0;
  int disconnectCalls = 0;
  int connectCalls = 0;
  final List<String> sharedKeysCalled = [];
  List<AudioVideoCallParticipant> fakeParticipants = [];
  String? fakeOwnParticipantId;

  /// Records the name of each operation as it completes, in call order.
  /// Tests can append to this list from SDK stubs to verify ordering.
  final List<String> callOrder = [];

  // Control whether disconnect throws an exception (for testing error paths)
  Exception? disconnectThrows;

  @override
  String? get ownParticipantId => fakeOwnParticipantId;

  @override
  List<AudioVideoCallParticipant> get participants => fakeParticipants;

  @override
  Future<void> setSharedKey(String key) async {
    sharedKeysCalled.add(key);
    callOrder.add('setSharedKey');
  }

  @override
  Future<void> ratchetKey(String participantId, int keyIndex) async {
    callOrder.add('ratchetKey');
  }

  @override
  Future<void> connect({
    required String url,
    required String token,
    Map<String, String> participantIdToDid = const {},
    OnCallE2EEStateChanged? onE2EEStateChanged,
    OnParticipantDisconnected? onParticipantDisconnected,
    void Function()? onParticipantsChanged,
  }) async {
    connectCalls++;
    callOrder.add('connect');
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async =>
      micCalls.add(enabled);

  @override
  Future<void> setCameraEnabled(bool enabled) async => cameraCalls.add(enabled);

  @override
  Future<void> switchCamera() async => switchCameraCalls++;

  @override
  Future<void> setSpeakerphoneEnabled(bool enabled) async =>
      speakerCalls.add(enabled);

  @override
  Future<void> forceRemoteKeyframe(String participantId) async {
    callOrder.add('forceRemoteKeyframe:$participantId');
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    callOrder.add('disconnect');
    if (disconnectThrows != null) {
      throw disconnectThrows!;
    }
  }
}
