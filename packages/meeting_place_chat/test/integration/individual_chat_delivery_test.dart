import 'package:collection/collection.dart';
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

  test('alice sends multiple messages', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobReceivedTwo = ChatTestHarness.collect(
      fixture.bobChatSDK,
      duration: const Duration(seconds: 10),
    );

    final messageIds = <String>[
      (await fixture.aliceChatSDK.sendTextMessage('Message#1')).messageId,
      (await fixture.aliceChatSDK.sendTextMessage('Message#2')).messageId,
    ];

    final aliceDelivered = ChatTestHarness.collect(
      fixture.aliceChatSDK,
      duration: const Duration(seconds: 10),
    );

    final bobMessageIds = (await bobReceivedTwo)
        .where((d) => d.event is ChatMessageEvent && d.chatItem != null)
        .map((d) => d.chatItem!.messageId)
        .toSet();
    expect(bobMessageIds.length, equals(2));

    final deliveredIds = (await aliceDelivered)
        .map((d) => d.event)
        .whereType<ChatMessageDeliveredEvent>()
        .expand((e) => e.messageIds)
        .toSet();
    expect(deliveredIds, containsAll(messageIds));

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
    await fixture.bobChatSDK.startChatSession();
    await fixture.aliceChatSDK.startChatSession();

    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );
    final aliceDelivered =
        ChatTestHarness.awaitEvent<ChatMessageDeliveredEvent>(
          fixture.aliceChatSDK,
        );

    final sentMessage = await fixture.aliceChatSDK.sendTextMessage(
      'Hello World!',
    );
    await aliceDelivered;

    final actualMessages = await fixture.aliceChatSDK.messages;
    expect(
      actualMessages
          .firstWhereOrNull((m) => m.messageId == sentMessage.messageId)
          ?.status,
      equals(ChatItemStatus.delivered),
    );

    await bobWait;
    expect((await fixture.bobChatSDK.messages).length, equals(1));
  });

  test(
    'replayed history rolls all buffered outbound messages to delivered',
    () async {
      await fixture.aliceChatSDK.startChatSession();

      final sentIds = <String>[
        (await fixture.aliceChatSDK.sendTextMessage('Buffered #1')).messageId,
        (await fixture.aliceChatSDK.sendTextMessage('Buffered #2')).messageId,
      ];

      final aliceLatestDelivered = ChatTestHarness.awaitItem(
        fixture.aliceChatSDK,
        where: (item) =>
            item is Message &&
            item.messageId == sentIds.last &&
            item.status == ChatItemStatus.delivered,
      );

      await fixture.bobChatSDK.startChatSession();
      await aliceLatestDelivered;

      final aliceMessages = await fixture.aliceChatSDK.messages;
      final byId = {
        for (final m in aliceMessages.cast<Message>()) m.messageId: m,
      };
      for (final id in sentIds) {
        expect(byId[id]?.status, ChatItemStatus.delivered, reason: 'id=$id');
      }
    },
  );

  test('message is shown as sent even for notification error', () async {
    final channel = fixture.aliceChannel;
    channel.otherPartyNotificationToken = 'invalid_token';
    await fixture.aliceSDK.coreSDK.updateChannel(channel);

    await fixture.aliceChatSDK.startChatSession();
    final actual = await fixture.aliceChatSDK.sendTextMessage(
      'Sample text message',
    );
    expect(actual.status, ChatItemStatus.sent);
  });
}
