import 'package:meeting_place_chat/src/transport/matrix/outgoing/message_edit_room_event.dart';
import 'package:test/test.dart';

import 'package:meeting_place_chat/src/entity/chat_mention.dart';

void main() {
  group('MessageEditRoomEvent', () {
    test('uses m.room.message wire type', () {
      final event = MessageEditRoomEvent(
        senderDid: 'did:test:alice',
        targetEventId: r'$abc',
        newText: 'hello world',
      );
      expect(event.type, 'm.room.message');
    });

    test('produces m.replace content with new_content and fallback body', () {
      final event = MessageEditRoomEvent(
        senderDid: 'did:test:alice',
        targetEventId: r'$abc',
        newText: 'hello world',
      );

      expect(event.content, {
        'msgtype': 'm.text',
        'body': '* hello world',
        'm.new_content': {'msgtype': 'm.text', 'body': 'hello world'},
        'm.relates_to': {'rel_type': 'm.replace', 'event_id': r'$abc'},
      });
    });

    test('includes Matrix mentions and formatted body when provided', () {
      final event = MessageEditRoomEvent(
        senderDid: 'did:test:alice',
        targetEventId: r'$abc',
        newText: 'hello @alice:example.org',
        mentions: const [
          ChatMention(
            target: '@alice:example.org',
            start: 6,
            length: 18,
            display: '@alice:example.org',
          ),
        ],
      );

      expect(event.content['m.mentions'], {
        'user_ids': ['@alice:example.org'],
      });
      expect(event.content['format'], 'org.matrix.custom.html');
      expect(
        event.content['formatted_body'],
        contains('https://matrix.to/#/@alice:example.org'),
      );
      expect(event.content['m.new_content'], {
        'body': 'hello @alice:example.org',
        'msgtype': 'm.text',
        'format': 'org.matrix.custom.html',
        'formatted_body':
            'hello <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a>',
        'm.mentions': {
          'user_ids': ['@alice:example.org'],
        },
      });
    });
  });
}
