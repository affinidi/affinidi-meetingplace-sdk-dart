import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:test/test.dart';

void main() {
  OngoingGroupCallParticipant participant({
    required String matrixUserId,
    String deviceId = 'DEV',
    bool isSelf = false,
    String? did,
  }) => OngoingGroupCallParticipant(
    matrixUserId: matrixUserId,
    deviceId: deviceId,
    isSelf: isSelf,
    did: did,
  );

  group('OngoingGroupCall', () {
    test('participantCount reflects all participants', () {
      final call = OngoingGroupCall(
        callId: 'c1',
        participants: [
          participant(matrixUserId: '@a:s'),
          participant(matrixUserId: '@b:s'),
          participant(matrixUserId: '@me:s', isSelf: true),
        ],
      );

      expect(call.participantCount, 3);
    });

    test('remoteParticipants excludes self memberships', () {
      final selfP = participant(matrixUserId: '@me:s', isSelf: true);
      final call = OngoingGroupCall(
        callId: 'c1',
        participants: [
          participant(matrixUserId: '@a:s'),
          selfP,
        ],
      );

      expect(call.remoteParticipants, [participant(matrixUserId: '@a:s')]);
      expect(call.remoteParticipants, isNot(contains(selfP)));
    });

    test('value equality by callId and participants', () {
      final a = OngoingGroupCall(
        callId: 'c1',
        participants: [participant(matrixUserId: '@a:s', did: 'did:a')],
      );
      final b = OngoingGroupCall(
        callId: 'c1',
        participants: [participant(matrixUserId: '@a:s', did: 'did:a')],
      );
      final c = OngoingGroupCall(
        callId: 'c2',
        participants: [participant(matrixUserId: '@a:s', did: 'did:a')],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('participant equality is field-sensitive', () {
      expect(
        participant(matrixUserId: '@a:s', did: 'did:a'),
        equals(participant(matrixUserId: '@a:s', did: 'did:a')),
      );
      expect(
        participant(matrixUserId: '@a:s', did: 'did:a'),
        isNot(equals(participant(matrixUserId: '@a:s', did: 'did:b'))),
      );
    });
  });
}
