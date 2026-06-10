@Tags(['serial'])
library;

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../utils/group_chat_fixture.dart';

void main() {
  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
  });

  tearDown(() {
    fixture.disposeSessions();
  });

  tearDownAll(() {
    fixture.disposeSessions();
  });

  test('group owner sends message to members', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final bobMessage = ChatTestHarness.awaitItem(
      fixture.bobChatSDK,
      where: (item) => item is Message && item.value == 'Hello Group!',
    );

    final charlieMessage = ChatTestHarness.awaitItem(
      fixture.charlieChatSDK,
      where: (item) => item is Message && item.value == 'Hello Group!',
    );

    await fixture.bobChatSDK.chatStreamSubscription;
    await fixture.charlieChatSDK.chatStreamSubscription;

    await fixture.aliceChatSDK.sendTextMessage('Hello Group!');

    expect((await bobMessage as Message).value, equals('Hello Group!'));
    expect((await charlieMessage as Message).value, equals('Hello Group!'));
  });

  test('send activity message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final charlieActivity = ChatTestHarness.awaitEvent<ChatActivityEvent>(
      fixture.charlieChatSDK,
    );

    await fixture.bobChatSDK.sendChatActivity();
    await charlieActivity;
  });

  test('group member sendCustomEvent delivers message to group', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final bobMessage = ChatTestHarness.awaitItem(
      fixture.bobChatSDK,
      where: (item) =>
          item is Message && item.value == 'Hello group via sendCustomEvent',
    );
    final charlieMessage = ChatTestHarness.awaitItem(
      fixture.charlieChatSDK,
      where: (item) =>
          item is Message && item.value == 'Hello group via sendCustomEvent',
    );

    await fixture.aliceChatSDK.sendCustomEvent(
      type: 'm.room.message',
      payload: {'body': 'Hello group via sendCustomEvent', 'msgtype': 'm.text'},
    );

    final receivedByBob = await bobMessage as Message;
    final receivedByCharlie = await charlieMessage as Message;

    expect(receivedByBob.value, equals('Hello group via sendCustomEvent'));
    expect(receivedByBob.senderDid, equals(fixture.groupOwnerDidDocument.id));

    expect(receivedByCharlie.value, equals('Hello group via sendCustomEvent'));
    expect(
      receivedByCharlie.senderDid,
      equals(fixture.groupOwnerDidDocument.id),
    );
  });

  test('group sendCustomEvent delivers message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobMessage = ChatTestHarness.awaitItem(
      fixture.bobChatSDK,
      where: (item) => item is Message && item.value == 'Notify group test',
    );

    await fixture.aliceChatSDK.sendCustomEvent(
      type: 'm.room.message',
      payload: {'body': 'Notify group test', 'msgtype': 'm.text'},
    );

    final received = await bobMessage as Message;
    expect(received.value, equals('Notify group test'));
    expect(received.senderDid, equals(fixture.groupOwnerDidDocument.id));
  });

  test(
    'replayed group history rolls all buffered outbound messages to delivered',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      await fixture.charlieChatSDK.startChatSession();

      final aliceSentIds = <String>[
        (await fixture.aliceChatSDK.sendTextMessage(
          'Group buffered #1',
        )).messageId,
        (await fixture.aliceChatSDK.sendTextMessage(
          'Group buffered #2',
        )).messageId,
      ];

      final aliceLatestDelivered = ChatTestHarness.awaitItem(
        fixture.aliceChatSDK,
        where: (item) =>
            item is Message &&
            item.messageId == aliceSentIds.last &&
            item.status == ChatItemStatus.delivered,
      );

      await fixture.bobChatSDK.startChatSession();
      await aliceLatestDelivered;

      final aliceMessages = await fixture.aliceChatSDK.messages;
      final byId = {
        for (final m in aliceMessages.cast<Message>()) m.messageId: m,
      };
      for (final id in aliceSentIds) {
        expect(byId[id]?.status, ChatItemStatus.delivered, reason: 'id=$id');
      }
    },
  );
}
