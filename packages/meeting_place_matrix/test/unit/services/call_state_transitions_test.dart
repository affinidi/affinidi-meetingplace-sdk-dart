import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/services/call_state_transitions.dart';
import 'package:test/test.dart';

void main() {
  group('canCancelBeforeAnswer', () {
    test('returns true for connecting', () {
      expect(canCancelBeforeAnswer(AudioVideoCallStatus.connecting), isTrue);
    });

    test('returns true for outgoingRinging', () {
      expect(
        canCancelBeforeAnswer(AudioVideoCallStatus.outgoingRinging),
        isTrue,
      );
    });

    test('returns false for waitingForKeys', () {
      expect(
        canCancelBeforeAnswer(AudioVideoCallStatus.waitingForKeys),
        isFalse,
      );
    });

    test('returns false for connected', () {
      expect(canCancelBeforeAnswer(AudioVideoCallStatus.connected), isFalse);
    });

    test('returns false for active', () {
      expect(canCancelBeforeAnswer(AudioVideoCallStatus.active), isFalse);
    });

    test('returns false for disconnected', () {
      expect(canCancelBeforeAnswer(AudioVideoCallStatus.disconnected), isFalse);
    });
  });

  group('canConnectOnPeerJoin', () {
    test('returns true for outgoingRinging', () {
      expect(
        canConnectOnPeerJoin(AudioVideoCallStatus.outgoingRinging),
        isTrue,
      );
    });

    test('returns true for waitingForKeys', () {
      expect(canConnectOnPeerJoin(AudioVideoCallStatus.waitingForKeys), isTrue);
    });

    test('returns false for connecting', () {
      expect(canConnectOnPeerJoin(AudioVideoCallStatus.connecting), isFalse);
    });

    test('returns false for connected', () {
      expect(canConnectOnPeerJoin(AudioVideoCallStatus.connected), isFalse);
    });

    test('returns false for active', () {
      expect(canConnectOnPeerJoin(AudioVideoCallStatus.active), isFalse);
    });

    test('returns false for disconnected', () {
      expect(canConnectOnPeerJoin(AudioVideoCallStatus.disconnected), isFalse);
    });
  });

  group('canTransitionToActive', () {
    test('returns true for outgoingRinging', () {
      expect(
        canTransitionToActive(AudioVideoCallStatus.outgoingRinging),
        isTrue,
      );
    });

    test('returns true for waitingForKeys', () {
      expect(
        canTransitionToActive(AudioVideoCallStatus.waitingForKeys),
        isTrue,
      );
    });

    test('returns true for connected', () {
      expect(canTransitionToActive(AudioVideoCallStatus.connected), isTrue);
    });

    test('returns false for connecting', () {
      expect(canTransitionToActive(AudioVideoCallStatus.connecting), isFalse);
    });

    test('returns false for active', () {
      expect(canTransitionToActive(AudioVideoCallStatus.active), isFalse);
    });

    test('returns false for disconnected', () {
      expect(canTransitionToActive(AudioVideoCallStatus.disconnected), isFalse);
    });
  });
}
