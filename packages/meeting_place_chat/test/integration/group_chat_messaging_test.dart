import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import 'utils/group_chat_fixture.dart';

void main() {
  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
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
}
