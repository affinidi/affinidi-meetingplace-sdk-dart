import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
import 'package:test/test.dart';

import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('sending reactions to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobChatCompleted = Completer<void>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          if (!bobChatCompleted.isCompleted) bobChatCompleted.complete();
        }
      });
    });

    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobChatCompleted.future;

    final messageReceivedTwoReactions = Completer<void>();
    final oneReactionRemovedFromMessage = Completer<void>();
    final message = (await fixture.bobChatSDK.messages).first as Message;

    var count = 0;
    await fixture.aliceChatSDK.chatStreamSubscription.then(
      (stream) => {
        stream!.listen((message) {
          if (MessageUtils.isType(
            message.plainTextMessage!,
            ChatProtocol.chatReaction,
          )) {
            count++;
            if (count == 2) messageReceivedTwoReactions.complete();
            if (count == 3) oneReactionRemovedFromMessage.complete();
          }
        }),
      },
    );

    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👋');
    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👍');
    await messageReceivedTwoReactions.future;

    final targetMessage =
        await fixture.aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(targetMessage.reactions, equals(['👋', '👍']));

    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👋');
    await oneReactionRemovedFromMessage.future;

    final updatedMessage =
        await fixture.aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(updatedMessage.reactions, equals(['👍']));
  });
}
