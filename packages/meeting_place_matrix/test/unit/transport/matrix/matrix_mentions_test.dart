import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/transport/matrix/matrix_mentions.dart';
import 'package:test/test.dart';

void main() {
  group('extractMatrixMentions', () {
    test('skips user mentions that are not present in the body text', () {
      final mentions = extractMatrixMentions({
        'body': 'hello there',
        'm.mentions': {
          'user_ids': ['@alice:example.org'],
        },
      });

      expect(mentions, isEmpty);
    });

    test('skips room mentions that are not present in the body text', () {
      final mentions = extractMatrixMentions({
        'body': 'hello there',
        'm.mentions': {'room': true},
      });

      expect(mentions, isEmpty);
    });

    test(
      'keeps mentions when the localpart fallback is present in the body',
      () {
        final mentions = extractMatrixMentions({
          'body': 'hello @alice',
          'm.mentions': {
            'user_ids': ['@alice:example.org'],
          },
        });

        expect(mentions, const [
          ChatMention(
            target: '@alice:example.org',
            start: 6,
            length: 6,
            display: '@alice',
          ),
        ]);
      },
    );
  });
}
