import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix_livekit/meeting_place_matrix_livekit.dart';
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
    sfuAllowedHosts: const ['*.example.com'],
  ),
  rtcDelegate: FakeWebRTCDelegate(),
  roomFactory: roomFactory ?? fakeLiveKitRoomFactory(),
);

MockMeetingPlaceCoreSDK _mockSdk() {
  final sdk = MockMeetingPlaceCoreSDK();
  when(() => sdk.incomingCallSignals).thenAnswer((_) => const Stream.empty());
  when(() => sdk.callDeclineSignals).thenAnswer((_) => const Stream.empty());
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

  group('secure configuration', () {
    test(
      'constructor throws when sfuAllowedHosts is empty in production mode',
      () {
        expect(
          () => MeetingPlaceLiveKitCallPlugin(
            options: MeetingPlaceLiveKitCallPluginOptions(
              livekitServiceUrl: Uri.parse('https://livekit.example.com'),
              // livekitSfuUrl omitted (null) => server-supplied production URL
              // with no allowlist must fail fast.
            ),
            rtcDelegate: FakeWebRTCDelegate(),
            roomFactory: fakeLiveKitRoomFactory(),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('must be non-empty when livekitSfuUrl is null'),
            ),
          ),
        );
      },
    );

    test('constructor succeeds in dev mode without allowlist', () {
      expect(
        () => MeetingPlaceLiveKitCallPlugin(
          options: MeetingPlaceLiveKitCallPluginOptions(
            livekitServiceUrl: Uri.parse('https://livekit.example.com'),
            livekitSfuUrl: Uri.parse('ws://livekit:7880'),
          ),
          rtcDelegate: FakeWebRTCDelegate(),
          roomFactory: fakeLiveKitRoomFactory(),
        ),
        returnsNormally,
      );
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

    test(
      'releases busy guard when session stream closes without terminal status',
      () async {
        final plugin = _plugin();
        plugin.initialize(sdk: _mockSdk());
        addTearDown(() async => plugin.dispose());

        final session1 = await plugin.startCall(
          otherPartyChannelDid: 'did:key:caller1',
          mediaType: CallMediaType.video,
        );
        expect(plugin.activeSession, same(session1));

        // Close the session's state stream without emitting a terminal status
        // by disposing it. The plugin must release the busy guard via onDone.
        await plugin.activeSession!.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(plugin.activeSession, isNull);

        final session2 = await plugin.startCall(
          otherPartyChannelDid: 'did:key:caller2',
          mediaType: CallMediaType.video,
        );

        expect(session2, isNotNull);
        expect(session2, isNot(same(session1)));
      },
    );
  });
}
