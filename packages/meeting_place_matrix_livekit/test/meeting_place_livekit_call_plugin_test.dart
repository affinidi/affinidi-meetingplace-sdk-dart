import 'package:meeting_place_matrix_livekit/meeting_place_matrix_livekit.dart';
import 'package:test/test.dart';

import 'fakes/fake_fallbacks.dart';

MeetingPlaceLiveKitCallPlugin _plugin({Uri? livekitServiceUrl}) =>
    MeetingPlaceLiveKitCallPlugin(
      options: MeetingPlaceLiveKitCallPluginOptions(
        livekitServiceUrl:
            livekitServiceUrl ?? Uri.parse('https://livekit.example.com'),
      ),
      rtcDelegate: FakeWebRTCDelegate(),
      roomFactory: fakeLiveKitRoomFactory(),
    );

void main() {
  group('isSupported', () {
    test('returns true when livekitServiceUrl host is non-empty', () {
      final plugin = _plugin(
        livekitServiceUrl: Uri.parse('https://livekit.example.com'),
      );
      expect(plugin.isSupported, isTrue);
    });

    test('returns false when livekitServiceUrl host is empty', () {
      final plugin = _plugin(livekitServiceUrl: Uri());
      expect(plugin.isSupported, isFalse);
    });
  });

  group('incomingCalls', () {
    test('is a broadcast stream — multiple listeners do not throw', () {
      final plugin = _plugin();
      final stream = plugin.incomingCalls;

      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});

      addTearDown(() {
        sub1.cancel();
        sub2.cancel();
      });
    });
  });

  group('acceptCall', () {
    test('throws for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(
        plugin.acceptCall(callId: 'unknown-call'),
        throwsA(isA<MeetingPlaceLiveKitCallOperationException>()),
      );
    });
  });

  group('declineCall', () {
    test('completes without throwing for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(plugin.declineCall(callId: 'unknown-call'), completes);
    });
  });
}
