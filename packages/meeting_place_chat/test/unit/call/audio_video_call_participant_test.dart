import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('AudioVideoCallParticipant', () {
    test('did defaults to null when not provided', () {
      const participant = AudioVideoCallParticipant(identity: '@alice:server');
      expect(participant.did, isNull);
    });

    test('retains the did passed to the constructor', () {
      const participant = AudioVideoCallParticipant(
        identity: '@alice:server',
        did: 'did:peer:alice',
      );
      expect(participant.did, 'did:peer:alice');
    });

    test('copyWith overrides the did', () {
      const participant = AudioVideoCallParticipant(
        identity: '@alice:server',
        did: 'did:peer:alice',
      );
      final updated = participant.copyWith(did: 'did:peer:bob');
      expect(updated.did, 'did:peer:bob');
      expect(updated.identity, '@alice:server');
    });

    test('copyWith preserves the existing did when omitted', () {
      const participant = AudioVideoCallParticipant(
        identity: '@alice:server',
        did: 'did:peer:alice',
      );
      final updated = participant.copyWith(isSpeaking: true);
      expect(updated.did, 'did:peer:alice');
      expect(updated.isSpeaking, isTrue);
    });
  });
}
