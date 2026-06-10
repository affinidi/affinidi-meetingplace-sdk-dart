import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('sendCustomEvent delivers message to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    await fixture.bobChatSDK.chatStreamSubscription;
    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );

    await fixture.aliceChatSDK.sendCustomEvent(
      type: ChatProtocol.chatMessage.value,
      payload: {
        'text': 'Hello via sendCustomEvent',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await bobWait;
    final received = (await fixture.bobChatSDK.messages).first as Message;
    expect(received.value, equals('Hello via sendCustomEvent'));
    expect(
      received.senderDid,
      equals(fixture.aliceChannel.permanentChannelDid),
    );
  });

  test('sendCustomEvent message is persisted in repository', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );

    await fixture.aliceChatSDK.sendCustomEvent(
      type: ChatProtocol.chatMessage.value,
      payload: {
        'text': 'Persist test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await bobWait;
    final received = (await fixture.bobChatSDK.messages).first as Message;
    expect(received.value, equals('Persist test'));
    expect(
      received.senderDid,
      equals(fixture.aliceChannel.permanentChannelDid),
    );

    final bobMessages = await fixture.bobChatSDK.messages;
    expect(
      bobMessages.whereType<Message>().any((m) => m.value == 'Persist test'),
      isTrue,
      reason: 'Message should be persisted in Bob\'s repository',
    );
  });
}
