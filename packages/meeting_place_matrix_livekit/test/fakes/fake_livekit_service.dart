import 'package:livekit_client/livekit_client.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant;
import 'package:meeting_place_matrix_livekit/src/services/livekit_service.dart';

class FakeLivekitService extends LivekitService {
  final List<bool> micCalls = [];
  final List<bool> cameraCalls = [];
  final List<bool> speakerCalls = [];
  int switchCameraCalls = 0;
  int disconnectCalls = 0;
  int connectCalls = 0;
  List<AudioVideoCallParticipant> fakeParticipants = [];

  /// Records the name of each operation as it completes, in call order.
  /// Tests can append to this list from SDK stubs to verify ordering.
  final List<String> callOrder = [];

  // Control whether disconnect throws an exception (for testing error paths)
  Exception? disconnectThrows;

  @override
  Future<void> connect({
    required String url,
    required String token,
    required BaseKeyProvider keyProvider,
    Map<String, String> participantIdToDid = const {},
    OnE2EEStateChanged? onE2EEStateChanged,
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
  Future<void> disconnect() async {
    disconnectCalls++;
    if (disconnectThrows != null) {
      throw disconnectThrows!;
    }
  }

  @override
  List<AudioVideoCallParticipant> get participants => fakeParticipants;
}
