import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('Message serialization', () {
    test('mentions round-trip through toJson/fromJson', () {
      final message = Message(
        chatId: 'c1',
        messageId: 'm1',
        senderDid: 'did:example:alice',
        value: 'hello @alice and @room',
        mentions: const [
          ChatMention(
            target: '@alice:example.org',
            start: 6,
            length: 6,
            display: '@alice',
          ),
          ChatMention(
            target: '@room',
            start: 17,
            length: 5,
            display: '@room',
            isRoomMention: true,
          ),
        ],
        isFromMe: false,
        dateCreated: DateTime.utc(2026, 1, 1),
        status: ChatItemStatus.received,
      );

      final restored = Message.fromJson(message.toJson());

      expect(restored.mentions, message.mentions);
      expect(restored.value, message.value);
    });
  });
}
