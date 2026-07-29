import 'package:meeting_place_matrix/src/call/ongoing_group_call_mapper.dart';
import 'package:meeting_place_matrix/src/matrix_user_id_binding.dart';
import 'package:test/test.dart';

import '../mocks/mocks.dart';

const _serverName = 'matrix.example.com';

/// The Matrix user ID a DID publishes under [_serverName]. Uses the real
/// derivation so the test matches production resolution, not a fake.
String _userIdFor(String did) => deriveMatrixUserId(did, _serverName);

void main() {
  group('buildOngoingGroupCall', () {
    test('returns null for no memberships', () {
      expect(
        buildOngoingGroupCall(
          memberships: const [],
          ownChannelDid: 'did:self',
          serverName: _serverName,
          candidateDids: const {},
        ),
        isNull,
      );
    });

    test('maps memberships and resolves DIDs from candidates', () {
      final selfUser = _userIdFor('did:self');
      final peerUser = _userIdFor('did:peer');
      final result = buildOngoingGroupCall(
        memberships: [
          MockCallMembership(
            callId: 'call-1',
            userId: selfUser,
            deviceId: 'DEV_SELF',
          ),
          MockCallMembership(
            callId: 'call-1',
            userId: peerUser,
            deviceId: 'DEV_PEER',
          ),
        ],
        ownChannelDid: 'did:self',
        serverName: _serverName,
        candidateDids: const {'did:self', 'did:peer'},
      );

      expect(result, isNotNull);
      expect(result!.callId, 'call-1');
      expect(result.participantCount, 2);
      final self = result.participants.firstWhere((p) => p.isSelf);
      expect(self.did, 'did:self');
      final peer = result.participants.firstWhere((p) => !p.isSelf);
      expect(peer.did, 'did:peer');
      expect(result.remoteParticipants, [peer]);
    });

    test('keeps unresolved memberships with a null DID', () {
      final result = buildOngoingGroupCall(
        memberships: [
          MockCallMembership(
            callId: 'call-1',
            userId: '@stranger:$_serverName',
            deviceId: 'DEV_X',
          ),
        ],
        ownChannelDid: 'did:self',
        serverName: _serverName,
        candidateDids: const {'did:self'},
      );

      expect(result, isNotNull);
      expect(result!.participants.single.did, isNull);
      expect(result.participants.single.isSelf, isFalse);
    });

    test('selects the call generation with the most members', () {
      final result = buildOngoingGroupCall(
        memberships: [
          MockCallMembership(
            callId: 'call-stale',
            userId: '@a:$_serverName',
            deviceId: 'DEV_A',
          ),
          MockCallMembership(
            callId: 'call-live',
            userId: '@b:$_serverName',
            deviceId: 'DEV_B',
          ),
          MockCallMembership(
            callId: 'call-live',
            userId: '@c:$_serverName',
            deviceId: 'DEV_C',
          ),
        ],
        ownChannelDid: 'did:self',
        serverName: _serverName,
        candidateDids: const {},
      );

      expect(result!.callId, 'call-live');
      expect(result.participantCount, 2);
      expect(
        result.participants.every((p) => p.matrixUserId != '@a:$_serverName'),
        isTrue,
      );
    });

    test('breaks call-generation ties by smallest callId', () {
      final result = buildOngoingGroupCall(
        memberships: [
          MockCallMembership(
            callId: 'call-b',
            userId: '@x:$_serverName',
            deviceId: 'DEV_X',
          ),
          MockCallMembership(
            callId: 'call-a',
            userId: '@y:$_serverName',
            deviceId: 'DEV_Y',
          ),
        ],
        ownChannelDid: 'did:self',
        serverName: _serverName,
        candidateDids: const {},
      );

      expect(result!.callId, 'call-a');
    });
  });
}
