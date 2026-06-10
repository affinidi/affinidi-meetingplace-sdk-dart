import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../../utils/contact_card_fixture.dart' as fixtures;
import '../../../utils/setup_chat_sdk.dart';
import '../../../utils/storage/in_memory_storage.dart';
import '../../utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('chat history resumes and is chat-scoped', () async {
    await fixture.bobChatSDK.startChatSession();
    await fixture.aliceChatSDK.startChatSession();

    final bobMessage = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );

    await fixture.aliceChatSDK.sendTextMessage('Hello World!');
    await bobMessage;

    await fixture.aliceChatSDK.endChatSession();

    // On resume Alice will receive her chat history
    await fixture.aliceChatSDK.startChatSession();
    expect((await fixture.aliceChatSDK.messages).length, equals(1));
    await fixture.aliceChatSDK.endChatSession();

    // Different chat -> history should be empty
    final setup = SetupChatSdk();
    final charlieSDK = await setup.createCoreSDK(
      fixtures.ContactCardFixture.charliePrimaryCardInfo,
    );

    final (aliceCharlieChannel, _) = await setup.establishIndividualConnection(
      aliceSDK: fixture.aliceSDK,
      bobSDK: charlieSDK,
    );

    final aliceChatWithCharlie = await setup.createChatSdk(
      sdkInstance: fixture.aliceSDK,
      channel: aliceCharlieChannel,
    );

    await aliceChatWithCharlie.startChatSession();
    expect((await aliceChatWithCharlie.messages).length, isZero);
    await aliceChatWithCharlie.endChatSession();

    expect((await fixture.bobChatSDK.messages).length, equals(1));
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

  test(
    'keeps message history if new chat SDK instance is initialized',
    () async {
      final storage = InMemoryStorage();
      final setup = SetupChatSdk();

      final chatSDK = await setup.createChatSdk(
        sdkInstance: fixture.aliceSDK,
        channel: fixture.aliceChannel,
        storage: storage,
      );

      await chatSDK.sendTextMessage('Hello World!');
      expect((await chatSDK.messages).length, equals(1));
      await chatSDK.endChatSession();

      final chatSDKNewInstance = await setup.createChatSdk(
        sdkInstance: fixture.aliceSDK,
        channel: fixture.aliceChannel,
        storage: storage,
      );

      expect((await chatSDKNewInstance.messages).length, equals(1));
      await chatSDKNewInstance.endChatSession();
    },
  );
}
