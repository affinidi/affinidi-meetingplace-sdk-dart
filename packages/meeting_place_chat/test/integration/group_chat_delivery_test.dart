import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import 'utils/group_chat_fixture.dart';

void main() {
  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
  });

  tearDown(() {
    fixture.disposeSessions();
  });

  test(
    'replayed group history rolls all buffered outbound messages to delivered',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      await fixture.charlieChatSDK.startChatSession();

      final aliceSentIds = <String>[
        (await fixture.aliceChatSDK.sendTextMessage('Group buffered #1'))
            .messageId,
        (await fixture.aliceChatSDK.sendTextMessage('Group buffered #2'))
            .messageId,
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
