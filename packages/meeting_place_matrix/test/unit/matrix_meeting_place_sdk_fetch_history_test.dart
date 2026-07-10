import 'package:meeting_place_matrix/src/matrix_user_id_binding.dart';
import 'package:test/test.dart';

const _serverName = 'matrix.example.com';
const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';

void main() {
  group('resolveSenderDidFromCandidates — sender DID resolution', () {
    test('resolves DID for the other party', () {
      final bobUserId = deriveMatrixUserId(_bobDid, _serverName);

      final result = resolveSenderDidFromCandidates(
        matrixUserId: bobUserId,
        serverName: _serverName,
        candidateDids: [_aliceDid, _bobDid],
      );

      expect(result, equals(_bobDid));
    });

    test('resolves DID to self when sender is the receiver', () {
      final aliceUserId = deriveMatrixUserId(_aliceDid, _serverName);

      final result = resolveSenderDidFromCandidates(
        matrixUserId: aliceUserId,
        serverName: _serverName,
        candidateDids: [_aliceDid, _bobDid],
      );

      expect(result, equals(_aliceDid));
    });

    test('returns null when sender_id matches no known DID', () {
      final result = resolveSenderDidFromCandidates(
        matrixUserId: '@unknown_user:$_serverName',
        serverName: _serverName,
        candidateDids: [_aliceDid, _bobDid],
      );

      expect(result, isNull);
    });

    test('returns null for empty candidate list', () {
      final aliceUserId = deriveMatrixUserId(_aliceDid, _serverName);

      final result = resolveSenderDidFromCandidates(
        matrixUserId: aliceUserId,
        serverName: _serverName,
        candidateDids: [],
      );

      expect(result, isNull);
    });
  });
}
