import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fakes/fake_fallbacks.dart';
import 'fakes/fake_livekit_service.dart';
import 'mocks/mocks.dart';

MeetingPlaceLiveKitCallPlugin _plugin({
  Uri? livekitServiceUrl,
  LiveKitRoomFactory? roomFactory,
}) => MeetingPlaceLiveKitCallPlugin(
  options: MeetingPlaceLiveKitCallPluginOptions(
    livekitServiceUrl:
        livekitServiceUrl ?? Uri.parse('https://livekit.example.com'),
  ),
  rtcDelegate: FakeWebRTCDelegate(),
  roomFactory: roomFactory ?? fakeLiveKitRoomFactory(),
);

MockMeetingPlaceMatrixSDK _mockSdk() {
  final sdk = MockMeetingPlaceMatrixSDK();
  when(() => sdk.callSignals).thenAnswer((_) => const Stream.empty());
  when(
    () => sdk.getChannelByOtherPartyPermanentDid(any()),
  ).thenThrow(Exception('stub: not needed for this test'));
  return sdk;
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockDidManager());
  });

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

  group('startCall', () {
    test(
      'disposes previous session and creates a new one when called twice',
      () async {
        final rooms = <FakeLiveKitRoom>[];
        final plugin = _plugin(
          roomFactory: (did) {
            final room = FakeLiveKitRoom();
            rooms.add(room);
            return room;
          },
        );
        plugin.initialize(sdk: _mockSdk());
        addTearDown(() async => plugin.dispose());

        const did = 'did:key:other';

        final session1 = await plugin.startCall(
          otherPartyChannelDid: did,
          mediaType: CallMediaType.video,
        );

        // Give the background joinCall a moment to start and hit the
        // SDK stub (which throws). The service catches it and swallows
        // it because _isDisposed will be true after disposeContainer().
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final session2 = await plugin.startCall(
          otherPartyChannelDid: did,
          mediaType: CallMediaType.video,
        );

        // Two separate rooms = two separate sessions created.
        expect(rooms.length, 2);
        // First room was disconnected — not abandoned.
        expect(
          rooms[0].disconnectCalls,
          greaterThan(0),
          reason: 'first session was cleaned up',
        );
        // A distinct session handle was returned.
        expect(session1, isNot(same(session2)));
      },
    );
  });
}
