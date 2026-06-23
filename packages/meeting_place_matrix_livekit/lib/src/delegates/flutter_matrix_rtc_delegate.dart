import 'package:flutter_webrtc/flutter_webrtc.dart' as flutter_webrtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart' as matrix;
import 'package:webrtc_interface/webrtc_interface.dart' as webrtc;

import 'matrix_encryption_key_provider_adapter.dart';

/// Concrete [matrix.WebRTCDelegate] that bridges MatrixRTC to flutter_webrtc.
///
/// Lives in the plugin so that the SDK stays pure Dart. Created once per app
/// session and injected into `matrix.VoIP` at startup via
/// `MeetingPlaceCoreSDK.initializeMatrixRTC()`.
///
/// The [keyProvider] field is set by the call service before a call
/// starts, allowing per-participant E2EE keys distributed by MatrixRTC to
/// flow into the LiveKit FrameCryptor layer.
class FlutterMatrixRTCDelegate implements matrix.WebRTCDelegate {
  lk.BaseKeyProvider? _livekitKeyProvider;

  /// Sets the LiveKit [lk.BaseKeyProvider] that should receive per-participant
  /// E2EE keys distributed by MatrixRTC.
  ///
  /// Call before entering a call. Pass `null` to clear after the call ends.
  // ignore: use_setters_to_change_properties
  void updateKeyProvider(lk.BaseKeyProvider? provider) {
    _livekitKeyProvider = provider;
  }

  @override
  matrix.EncryptionKeyProvider? get keyProvider => _livekitKeyProvider != null
      ? MatrixEncryptionKeyProviderAdapter(_livekitKeyProvider!)
      : null;

  @override
  webrtc.MediaDevices get mediaDevices => flutter_webrtc.navigator.mediaDevices;

  @override
  Future<webrtc.RTCPeerConnection> createPeerConnection(
    Map<String, dynamic> configuration, [
    Map<String, dynamic> constraints = const {},
  ]) => flutter_webrtc.createPeerConnection(configuration, constraints);

  @override
  Future<void> playRingtone() async {}

  @override
  Future<void> stopRingtone() async {}

  @override
  Future<void> registerListeners(matrix.CallSession session) async {}

  @override
  Future<void> handleNewCall(matrix.CallSession session) async {}

  @override
  Future<void> handleCallEnded(matrix.CallSession session) async {}

  @override
  Future<void> handleMissedCall(matrix.CallSession session) async {}

  @override
  Future<void> handleNewGroupCall(matrix.GroupCallSession session) async {}

  @override
  Future<void> handleGroupCallEnded(matrix.GroupCallSession session) async {}

  @override
  bool get isWeb => false;

  @override
  bool get canHandleNewCall => false;
}
