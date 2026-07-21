import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/didcomm/protocol.dart'
    as protocol;
import 'package:test/test.dart';

void main() {
  group('ChatSuggestion', () {
    test('serializes to the suggestion DIDComm protocol', () {
      final message = protocol.ChatSuggestion.create(
        from: 'did:test:agent',
        to: const ['did:test:user'],
        relatedMessageId: 'message-123',
        text: 'Suggested reply',
      ).toPlainTextMessage();

      expect(message.type.toString(), ChatProtocol.suggestion.value);
      expect(message.from, 'did:test:agent');
      expect(message.to, ['did:test:user']);
      expect(message.body, {
        'related_message_id': 'message-123',
        'text': 'Suggested reply',
      });
    });
  });

  group('ChatSuggestionMessage', () {
    test('builds a DIDComm payload from constructor fields', () {
      final message = ChatSuggestionMessage(
        senderDid: 'did:test:agent',
        recipientDid: 'did:test:user',
        mediatorDid: 'did:test:mediator',
        relatedMessageId: 'message-123',
        text: 'Suggested reply',
      );

      expect(message.senderDid, 'did:test:agent');
      expect(message.recipientDid, 'did:test:user');
      expect(message.mediatorDid, 'did:test:mediator');
      expect(message.payload.type.toString(), ChatProtocol.suggestion.value);
      expect(message.payload.from, 'did:test:agent');
      expect(message.payload.to, ['did:test:user']);
      expect(message.payload.body, {
        'related_message_id': 'message-123',
        'text': 'Suggested reply',
      });
    });
  });
}