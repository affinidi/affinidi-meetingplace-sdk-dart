import 'package:meeting_place_chat/src/transport/matrix/outgoing/matrix_room_message_builder.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/text_message_room_event.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
  const builder = MatrixRoomMessageBuilder();
  const senderDid = 'did:test:alice';
  const notification = IndividualChannelNotification(
    recipientDid: 'did:test:bob',
    type: 'chat-activity',
  );

  group('MatrixRoomMessageBuilder', () {
    test('builds TextMessageRoomEvent for plain text', () {
      final result = builder.build(
        senderDid: senderDid,
        text: 'Hello',
        notification: notification,
      );

      expect(result, isA<TextMessageRoomEvent>());
      expect(result.content['body'], 'Hello');
    });
  });
}
