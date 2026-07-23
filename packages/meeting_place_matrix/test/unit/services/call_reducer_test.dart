import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/services/call_command.dart';
import 'package:meeting_place_matrix/src/services/call_event.dart';
import 'package:meeting_place_matrix/src/services/call_reducer.dart';
import 'package:test/test.dart';

AudioVideoCallState _idle() => AudioVideoCallState.initial;

AudioVideoCallState _stateWith(AudioVideoCallStatus status) =>
    _idle().copyWith(status: status);

void main() {
  group('callTransition', () {
    group('CallJoinCompleted', () {
      test('caller join sets role and callId, no timer commands', () {
        final result = callTransition(
          _idle(),
          CallJoinCompleted(
            ownRole: CallRole.caller,
            callId: 'call-1',
            isRejoin: false,
            hasPeer: false,
          ),
        );
        expect(result.accepted, isTrue);
        expect(result.state.ownRole, CallRole.caller);
        expect(result.state.callId, 'call-1');
        expect(result.commands, isEmpty);
      });

      test('recipient join without peer → waitingForKeys + e2ee timer', () {
        final result = callTransition(
          _idle(),
          CallJoinCompleted(
            ownRole: CallRole.recipient,
            callId: 'call-1',
            isRejoin: false,
            hasPeer: false,
          ),
        );
        expect(result.state.status, AudioVideoCallStatus.waitingForKeys);
        expect(result.commands, contains(isA<StartE2eeTimeout>()));
      });

      test('recipient join with peer → connected + e2ee timer', () {
        final result = callTransition(
          _idle(),
          CallJoinCompleted(
            ownRole: CallRole.recipient,
            callId: 'call-1',
            isRejoin: false,
            hasPeer: true,
          ),
        );
        expect(result.state.status, AudioVideoCallStatus.connected);
        expect(result.state.callStartedAt, isNotNull);
        expect(result.commands, contains(isA<StartE2eeTimeout>()));
      });
    });

    group('CallInviteSent', () {
      test('transitions to outgoingRinging and starts outgoing timeout', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.connecting),
          CallInviteSent(participants: const []),
        );
        expect(result.state.status, AudioVideoCallStatus.outgoingRinging);
        expect(result.commands, contains(isA<StartOutgoingTimeout>()));
      });
    });

    group('CallPeerJoined', () {
      test(
        'from outgoingRinging → connected + cancel outgoing + start e2ee',
        () {
          final result = callTransition(
            _stateWith(AudioVideoCallStatus.outgoingRinging),
            CallPeerJoined(
              participants: const [],
              callStartedAt: DateTime(2024),
            ),
          );
          expect(result.state.status, AudioVideoCallStatus.connected);
          expect(result.commands, contains(isA<CancelOutgoingTimeout>()));
          expect(result.commands, contains(isA<StartE2eeTimeout>()));
        },
      );

      test('from waitingForKeys → connected', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.waitingForKeys),
          CallPeerJoined(participants: const [], callStartedAt: DateTime(2024)),
        );
        expect(result.state.status, AudioVideoCallStatus.connected);
      });

      test(
        'from connected (already connected) → still connected, no status change',
        () {
          final result = callTransition(
            _stateWith(AudioVideoCallStatus.connected),
            CallPeerJoined(
              participants: const [],
              callStartedAt: DateTime(2024),
            ),
          );
          expect(result.state.status, AudioVideoCallStatus.connected);
          expect(result.commands, isNot(contains(isA<StartE2eeTimeout>())));
        },
      );
    });

    group('CallPeerKeyed', () {
      for (final status in [
        AudioVideoCallStatus.outgoingRinging,
        AudioVideoCallStatus.waitingForKeys,
        AudioVideoCallStatus.connected,
      ]) {
        test('from $status → active + cancel both timers', () {
          final result = callTransition(
            _stateWith(status),
            CallPeerKeyed(participants: const []),
          );
          expect(result.accepted, isTrue);
          expect(result.state.status, AudioVideoCallStatus.active);
          expect(result.commands, contains(isA<CancelOutgoingTimeout>()));
          expect(result.commands, contains(isA<CancelE2eeTimeout>()));
        });
      }

      test('from active → ignored (no-op)', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.active),
          CallPeerKeyed(participants: const []),
        );
        expect(result.accepted, isFalse);
      });
    });

    group('CallDeclineReceived', () {
      for (final status in [
        AudioVideoCallStatus.connecting,
        AudioVideoCallStatus.outgoingRinging,
      ]) {
        test('from $status → declined + cleanup commands', () {
          final result = callTransition(
            _stateWith(status),
            CallDeclineReceived(),
          );
          expect(result.state.status, AudioVideoCallStatus.declined);
          expect(result.commands, contains(isA<CancelOutgoingTimeout>()));
          expect(result.commands, contains(isA<LeaveMatrixCall>()));
          expect(result.commands, contains(isA<DisconnectRoom>()));
        });
      }

      test('from active → ignored', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.active),
          CallDeclineReceived(),
        );
        expect(result.accepted, isFalse);
      });
    });

    group('CallOutgoingTimeoutFired', () {
      test('from outgoingRinging → missed + leave + cancel signal', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.outgoingRinging),
          CallOutgoingTimeoutFired(),
        );
        expect(result.state.status, AudioVideoCallStatus.missed);
        expect(result.commands, contains(isA<LeaveMatrixCall>()));
        expect(result.commands, contains(isA<DisconnectRoom>()));
        expect(result.commands, contains(isA<SendCallCancel>()));
      });

      test('from connected → ignored', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.connected),
          CallOutgoingTimeoutFired(),
        );
        expect(result.accepted, isFalse);
      });
    });

    group('CallE2eeTimeoutFired', () {
      test('from waitingForKeys → connected', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.waitingForKeys),
          CallE2eeTimeoutFired(participants: const []),
        );
        expect(result.state.status, AudioVideoCallStatus.connected);
      });

      test('from connected → ignored', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.connected),
          CallE2eeTimeoutFired(participants: const []),
        );
        expect(result.accepted, isFalse);
      });
    });

    group('CallLeaveRequested', () {
      test('active last-leaver → disconnecting + outcome command', () {
        final state = _idle().copyWith(
          status: AudioVideoCallStatus.active,
          callId: 'call-1',
          callStartedAt: DateTime(2024),
        );
        final result = callTransition(
          state,
          CallLeaveRequested(hasPeer: false, cancelledBeforeAnswer: false),
        );
        expect(result.state.status, AudioVideoCallStatus.disconnecting);
        expect(
          result.commands,
          contains(
            predicate<CallCommand>(
              (c) => c is SendCallOutcome && c.callId == 'call-1',
            ),
          ),
        );
      });

      test('active with peer → disconnecting, no outcome command', () {
        final state = _idle().copyWith(
          status: AudioVideoCallStatus.active,
          callId: 'call-1',
          callStartedAt: DateTime(2024),
        );
        final result = callTransition(
          state,
          CallLeaveRequested(hasPeer: true, cancelledBeforeAnswer: false),
        );
        expect(result.state.status, AudioVideoCallStatus.disconnecting);
        expect(result.commands, isNot(contains(isA<SendCallOutcome>())));
      });

      test(
        'cancelled before answer → disconnecting + cancel signal, no outcome',
        () {
          final result = callTransition(
            _stateWith(AudioVideoCallStatus.outgoingRinging),
            CallLeaveRequested(hasPeer: false, cancelledBeforeAnswer: true),
          );
          expect(result.state.status, AudioVideoCallStatus.disconnecting);
          expect(result.commands, contains(isA<SendCallCancel>()));
          expect(result.commands, isNot(contains(isA<SendCallOutcome>())));
        },
      );
    });

    group('CallJoinFailed', () {
      test('transitions to error with code', () {
        final result = callTransition(
          _stateWith(AudioVideoCallStatus.connecting),
          CallJoinFailed(errorCode: AudioVideoCallErrorCode.connectionFailed),
        );
        expect(result.state.status, AudioVideoCallStatus.error);
        expect(
          result.state.errorCode,
          AudioVideoCallErrorCode.connectionFailed,
        );
      });
    });
  });
}
