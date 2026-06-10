import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;
  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  setUpAll(() async {
    fixture = await IndividualChatFixture.create();
  });

  setUp(() async {
    aliceChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.aliceSDK,
      channel: fixture.aliceChannel,
    );
    bobChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.bobSDK,
      channel: fixture.bobChannel,
    );
  });

  tearDown(() async {
    await aliceChatSDK.endChatSession();
    await bobChatSDK.endChatSession();
  });

  tearDownAll(() async {
    await fixture.dispose();
  });

  test('alice sends multiple messages', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobReceivedTwo = ChatTestHarness.collect(
      bobChatSDK,
      duration: const Duration(seconds: 10),
    );

    final messageIds = <String>[
      (await aliceChatSDK.sendTextMessage('Message#1')).messageId,
      (await aliceChatSDK.sendTextMessage('Message#2')).messageId,
    ];

    final aliceDelivered = ChatTestHarness.collect(
      aliceChatSDK,
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

    final aliceRepositoryMessages = await aliceChatSDK.messages;
    expect(aliceRepositoryMessages.length, equals(2));
    expect(aliceRepositoryMessages[0].status, ChatItemStatus.delivered);
    expect(aliceRepositoryMessages[1].status, ChatItemStatus.delivered);

    final bobRepositoryMessages = await bobChatSDK.messages;
    expect(bobRepositoryMessages.length, equals(2));
    expect(bobRepositoryMessages[0].status, ChatItemStatus.received);
    expect(bobRepositoryMessages[1].status, ChatItemStatus.received);
  });

  test('sendTextMessage produces delivered status for sender', () async {
    await bobChatSDK.startChatSession();
    await aliceChatSDK.startChatSession();

    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(bobChatSDK);
    final aliceDelivered =
        ChatTestHarness.awaitEvent<ChatMessageDeliveredEvent>(aliceChatSDK);

    final sentMessage = await aliceChatSDK.sendTextMessage('Hello World!');
    await aliceDelivered;

    final actualMessages = await aliceChatSDK.messages;
    expect(
      actualMessages
          .firstWhereOrNull((m) => m.messageId == sentMessage.messageId)
          ?.status,
      equals(ChatItemStatus.delivered),
    );

    await bobWait;
    expect((await bobChatSDK.messages).length, equals(1));
  });

  test(
    'replayed history rolls all buffered outbound messages to delivered',
    () async {
      await aliceChatSDK.startChatSession();

      final sentIds = <String>[
        (await aliceChatSDK.sendTextMessage('Buffered #1')).messageId,
        (await aliceChatSDK.sendTextMessage('Buffered #2')).messageId,
      ];

      final aliceLatestDelivered = ChatTestHarness.awaitItem(
        aliceChatSDK,
        where: (item) =>
            item is Message &&
            item.messageId == sentIds.last &&
            item.status == ChatItemStatus.delivered,
      );

      await bobChatSDK.startChatSession();
      await aliceLatestDelivered;

      final aliceMessages = await aliceChatSDK.messages;
      final byId = {
        for (final m in aliceMessages.cast<Message>()) m.messageId: m,
      };
      for (final id in sentIds) {
        expect(byId[id]?.status, ChatItemStatus.delivered, reason: 'id=$id');
      }
    },
  );
}
