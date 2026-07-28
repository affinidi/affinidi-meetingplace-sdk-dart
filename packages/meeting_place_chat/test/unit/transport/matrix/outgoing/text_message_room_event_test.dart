import 'package:meeting_place_chat/src/entity/chat_mention.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/text_message_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('TextMessageRoomEvent', () {
    test('uses m.room.message wire type', () {
      final event = TextMessageRoomEvent(
        senderDid: 'did:test:alice',
        text: 'hello world',
      );

      expect(event.type, 'm.room.message');
      expect(event.content, {'body': 'hello world', 'msgtype': 'm.text'});
    });

    test('includes Matrix mentions and formatted body when provided', () {
      final event = TextMessageRoomEvent(
        senderDid: 'did:test:alice',
        text: 'hello @alice:example.org and @room',
        mentions: const [
          ChatMention(
            target: '@alice:example.org',
            start: 6,
            length: 18,
            display: '@alice:example.org',
          ),
          ChatMention(
            target: '@room',
            start: 29,
            length: 5,
            display: '@room',
            isRoomMention: true,
          ),
        ],
      );

      expect(event.content['m.mentions'], {
        'user_ids': ['@alice:example.org'],
        'room': true,
      });
      expect(event.content['format'], 'org.matrix.custom.html');
      expect(
        event.content['formatted_body'],
        'hello <a href="https://matrix.to/#/@alice:example.org">@alice:example.org</a> and <a href="https://matrix.to/#/@room">@room</a>',
      );
    });
  });
}
