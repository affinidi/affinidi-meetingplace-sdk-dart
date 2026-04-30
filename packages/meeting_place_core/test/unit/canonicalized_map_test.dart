import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/extensions/canonicalized_map.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalizedMap', () {
    test('canonicalizes nested maps recursively', () {
      final input = <String, dynamic>{
        'zebra': 1,
        'alpha': <String, dynamic>{'delta': 4, 'beta': 2},
        'items': <dynamic>[
          <String, dynamic>{'y': 2, 'x': 1},
          'value',
        ],
      };

      expect(input.canonicalized(), {
        'alpha': {'beta': 2, 'delta': 4},
        'items': [
          {'x': 1, 'y': 2},
          'value',
        ],
        'zebra': 1,
      });
    });

    test('contact card profile hash is stable for equivalent map ordering', () {
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
