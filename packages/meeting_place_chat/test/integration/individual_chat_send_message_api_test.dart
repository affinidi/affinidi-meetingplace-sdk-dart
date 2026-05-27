import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('sendRoomEvent delivers message to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );

    final event = CustomRoomEvent(
      type: ChatProtocol.chatMessage.value,
      content: {
        'text': 'Hello via sendRoomEvent',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendRoomEvent(event);

    await bobWait;
    final received = (await fixture.bobChatSDK.messages).first as Message;
    expect(received.value, equals('Hello via sendRoomEvent'));
    expect(received.senderDid, equals(fixture.aliceSDK.didDocument.id));
  });

  test('sendRoomEvent message is persisted in repository', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );

    final event = CustomRoomEvent(
      type: ChatProtocol.chatMessage.value,
      content: {
        'text': 'Persist test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendRoomEvent(event);

    await bobWait;
    final received = (await fixture.bobChatSDK.messages).first as Message;
    expect(received.value, equals('Persist test'));
    expect(received.senderDid, equals(fixture.aliceSDK.didDocument.id));

    final bobMessages = await fixture.bobChatSDK.messages;
    expect(
      bobMessages.whereType<Message>().any(
        (m) => m.value == 'Persist test',
      ),
      isTrue,
      reason: 'Message should be persisted in Bob\'s repository',
    );
  });
}
