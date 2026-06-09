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

    final bobCollect = ChatTestHarness.collect(
      fixture.bobChatSDK,
      duration: const Duration(seconds: 20),
    );

    await fixture.aliceChatSDK.sendCustomEvent(
      type: 'm.room.message',
      payload: {'body': 'Notify group test', 'msgtype': 'm.text'},
    );

    final all = await bobCollect;
    print('DEBUG bob received ${all.length} stream data:');
    for (final d in all) {
      print('  event=${d.event.runtimeType} chatItem=${d.chatItem}');
    }
    final received = all
        .map((d) => d.chatItem)
        .whereType<Message>()
        .firstWhere(
          (m) => m.value == 'Notify group test',
          orElse: () => throw StateError('no matching message'),
        );
    expect(received.value, equals('Notify group test'));
    expect(received.senderDid, equals(fixture.groupOwnerDidDocument.id));
  });
}
