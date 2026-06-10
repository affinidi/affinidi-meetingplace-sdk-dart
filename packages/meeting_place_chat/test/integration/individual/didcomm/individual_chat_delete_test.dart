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

  test('deleteMessage throws UnsupportedError on DIDComm transport', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobReceived = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );
    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobReceived;

    final aliceMessage = (await fixture.aliceChatSDK.messages).first as Message;

    expect(
      () => fixture.aliceChatSDK.deleteMessage(aliceMessage),
      throwsA(isA<UnsupportedError>()),
    );

    expect(
      () => fixture.aliceChatSDK.deleteMessage(aliceMessage, localOnly: true),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
