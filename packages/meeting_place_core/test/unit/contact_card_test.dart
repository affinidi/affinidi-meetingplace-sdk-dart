import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContactCard', () {
    test('profile hash is stable for equivalent map ordering', () {
      final first = ContactCard(
        did: 'did:test:alice',
        type: 'individual',
        contactInfo: {
          'lastName': 'Doe',
          'name': {'given': 'Alice', 'family': 'Doe'},
        },
      );

      final second = ContactCard(
        did: 'did:test:alice',
        type: 'individual',
        contactInfo: {
          'name': {'family': 'Doe', 'given': 'Alice'},
          'lastName': 'Doe',
        },
      );

      expect(first.contactInfo, equals(second.contactInfo));
      expect(first.profileHash, equals(second.profileHash));
    });
  });
}
