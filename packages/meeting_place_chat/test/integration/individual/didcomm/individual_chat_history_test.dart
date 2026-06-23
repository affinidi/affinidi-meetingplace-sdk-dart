import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('returns new messages from mediator', () async {
    final bobChat = await fixture.bobChatSDK.startChatSession();
    expect(bobChat.messages.length, equals(0));
    await fixture.bobChatSDK.endChatSession();

    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await fixture.bobChatSDK.startChatSession();

    final received = await ChatTestHarness.awaitItem(
      fixture.bobChatSDK,
      where: (item) => item is Message && item.value == 'Hello Bob!',
    );
    expect((received as Message).value, equals('Hello Bob!'));
  });
}
