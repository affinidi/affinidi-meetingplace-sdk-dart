import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
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

  test('alice sends multiple messages', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final aliceCompleter = Completer<void>();
    final bobCompleter = Completer<void>();

    final receivedMessageIds = <String>[];
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        final isChatMessage =
            message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value;

        if (isChatMessage &&
            !receivedMessageIds.contains(message.plainTextMessage!.id)) {
          receivedMessageIds.add(message.plainTextMessage!.id);
          if (receivedMessageIds.length == 2) {
            bobCompleter.complete();
          }
        }
      });
    });

    final messageIds = <String>[];
    messageIds.add(
      (await fixture.aliceChatSDK.sendTextMessage('Message#1')).messageId,
    );
    messageIds.add(
      (await fixture.aliceChatSDK.sendTextMessage('Message#2')).messageId,
    );

    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatDelivered.value) {
          final deliveredMessage = ChatDelivered.fromPlainTextMessage(
            message.plainTextMessage!,
          );

          final removed = messageIds.remove(deliveredMessage.body.messages[0]);
          if (messageIds.isEmpty && removed) {
            aliceCompleter.complete();
          }
        }
      });
    });

    await bobCompleter.future;
    await aliceCompleter.future;
    expect(receivedMessageIds.length, equals(2));

    final aliceRepositoryMessages = await fixture.aliceChatSDK.messages;
    expect(aliceRepositoryMessages.length, equals(2));

    expect(aliceRepositoryMessages[0].status, ChatItemStatus.delivered);
    expect(aliceRepositoryMessages[1].status, ChatItemStatus.delivered);

    final bobRepositoryMessages = await fixture.bobChatSDK.messages;
    expect(bobRepositoryMessages.length, equals(2));

    expect(bobRepositoryMessages[0].status, ChatItemStatus.received);
    expect(bobRepositoryMessages[1].status, ChatItemStatus.received);
  });

  test('sendTextMessage produces delivered status for sender', () async {
    final bobChatCompleted = Completer<void>();
    await fixture.bobChatSDK.startChatSession();

    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (!bobChatCompleted.isCompleted &&
            data.plainTextMessage?.type.toString() ==
                ChatProtocol.chatMessage.value) {
          bobChatCompleted.complete();
        }
      });
    });

    final aliceDelivered = Completer<void>();
    await fixture.aliceChatSDK.startChatSession();

    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (!aliceDelivered.isCompleted &&
            message.plainTextMessage?.type.toString() ==
                ChatProtocol.chatDelivered.value) {
          aliceDelivered.complete();
        }
      });
    });

    final sentMessage = await fixture.aliceChatSDK.sendTextMessage(
      'Hello World!',
    );
    await aliceDelivered.future;

    final actualMessages = await fixture.aliceChatSDK.messages;
    expect(
      actualMessages
          .firstWhereOrNull((m) => m.messageId == sentMessage.messageId)
          ?.status,
      equals(ChatItemStatus.delivered),
    );

    await bobChatCompleted.future;
    expect((await fixture.bobChatSDK.messages).length, equals(1));
  });

  test('message is shown as sent even for notification error', () async {
    final channel = await fixture.aliceSDK.coreSDK.getChannelByDid(
      fixture.aliceSDK.didDocument.id,
    );
    channel!.otherPartyNotificationToken = 'invalid_token';
    await fixture.aliceSDK.coreSDK.updateChannel(channel);

    await fixture.aliceChatSDK.startChatSession();
    final actual = await fixture.aliceChatSDK.sendTextMessage(
      'Sample text message',
    );
    expect(actual.status, ChatItemStatus.sent);
  });
}
