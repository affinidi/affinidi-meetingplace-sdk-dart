import 'dart:async';

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

  test('sending reactions to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobChat = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );
    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobChat;

    final message = (await fixture.bobChatSDK.messages).first as Message;

    // Collect reactions on Alice's side while Bob reacts twice then removes.
    final aliceReactions = ChatTestHarness.collect(
      fixture.aliceChatSDK,
      duration: const Duration(seconds: 10),
    );

    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👋');
    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👍');
    await Future<void>.delayed(const Duration(seconds: 2));

    final twoReactionMessage =
        await fixture.aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(twoReactionMessage.reactions, equals(['👋', '👍']));

    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👋');
    await aliceReactions;

    final updatedMessage =
        await fixture.aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(updatedMessage.reactions, equals(['👍']));
  });
}
