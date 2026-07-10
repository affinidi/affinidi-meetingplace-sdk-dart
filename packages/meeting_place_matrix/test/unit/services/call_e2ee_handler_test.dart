import 'dart:async';

import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/handlers/call_e2ee_handler.dart';
import 'package:test/test.dart';

import '../fakes/fake_livekit_service.dart';

void main() {
  late FakeLiveKitRoom room;
  late bool isDisposed;
  late int peerKeyedCalls;
  late String? lastKeyedParticipantId;
  late CallE2EEHandler handler;

  setUp(() {
    room = FakeLiveKitRoom();
    isDisposed = false;
    peerKeyedCalls = 0;
    lastKeyedParticipantId = null;
    handler = CallE2EEHandler(
      room: room,
      logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
      isDisposed: () => isDisposed,
      onPeerKeyed: (participantId) {
        peerKeyedCalls++;
        lastKeyedParticipantId = participantId;
      },
    );
  });

  tearDown(() => handler.cancelAll());

  group('onE2EEStateChanged', () {
    test(
      'invokes onPeerKeyed with participantId when participant reaches ok',
      () {
        handler.onE2EEStateChanged('participant-1', CallE2EEState.ok);

        expect(peerKeyedCalls, 1);
        expect(lastKeyedParticipantId, 'participant-1');
      },
    );

    test('does not invoke onPeerKeyed when service is disposed', () {
      isDisposed = true;

      handler.onE2EEStateChanged('participant-1', CallE2EEState.ok);

      expect(peerKeyedCalls, 0);
    });

    test(
      'schedules keyframe nudges while participant is missing a key',
      () async {
        handler.onE2EEStateChanged('participant-1', CallE2EEState.missingKey);

        await Future<void>.delayed(const Duration(milliseconds: 2100));

        expect(room.callOrder, contains('forceRemoteKeyframe:participant-1'));
      },
    );

    test('cancels keyframe nudges when participant reaches ok', () async {
      handler.onE2EEStateChanged('participant-1', CallE2EEState.missingKey);
      handler.onE2EEStateChanged('participant-1', CallE2EEState.ok);

      await Future<void>.delayed(const Duration(milliseconds: 2100));

      expect(
        room.callOrder,
        isNot(contains('forceRemoteKeyframe:participant-1')),
      );
      expect(peerKeyedCalls, 1);
    });
  });

  group('reset', () {
    test('clears stale missing-key tracking and cancels nudges', () async {
      handler.onE2EEStateChanged('participant-1', CallE2EEState.missingKey);

      handler.reset();

      await Future<void>.delayed(const Duration(milliseconds: 2100));

      expect(
        room.callOrder,
        isNot(contains('forceRemoteKeyframe:participant-1')),
      );
    });
  });
}
