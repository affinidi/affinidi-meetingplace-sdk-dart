import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/transport/matrix/matrix_mentions.dart';
import 'package:test/test.dart';

void main() {
  group('extractMatrixMentions', () {
    test('keeps user mentions that are not present in the body text', () {
      final mentions = extractMatrixMentions({
        'body': 'hello there',
        'm.mentions': {
          'user_ids': ['@alice:example.org'],
        },
      });

      expect(mentions, const [
        ChatMention(
          target: '@alice:example.org',
          start: 0,
          length: 0,
          display: '@alice',
        ),
      ]);
    });

    test('keeps did-targeted mentions rendered as a display name', () {
      final mentions = extractMatrixMentions({
        'body': '@Earl what do you know?',
        'm.mentions': {
          'user_ids': ['did:web:example.affinidi.io:user:1e378f28'],
        },
      });

      expect(mentions, const [
        ChatMention(
          target: 'did:web:example.affinidi.io:user:1e378f28',
          start: 0,
          length: 0,
          display: 'did:web:example.affinidi.io:user:1e378f28',
        ),
      ]);
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
