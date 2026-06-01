import 'package:meeting_place_chat/src/transport/matrix/outgoing/message_edit_room_event.dart';
import 'package:test/test.dart';

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
  });
}
