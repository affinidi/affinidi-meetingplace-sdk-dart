import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('wire delete broadcasts redaction and tombstones on receiver', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobReceived = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );
    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobReceived;

    final aliceMessage = (await fixture.aliceChatSDK.messages).first as Message;

    final bobTombstone = ChatTestHarness.awaitItem(
      fixture.bobChatSDK,
      where: (item) => item is Message && item.isDeleted,
    );

    await fixture.aliceChatSDK.deleteMessage(aliceMessage);

    final delivered = await bobTombstone as Message;
    expect(delivered.isDeleted, isTrue);
    expect(delivered.isDeletedLocally, isFalse);

    final aliceCopy =
        await fixture.aliceChatSDK.getMessageById(aliceMessage.messageId)
            as Message;
    expect(aliceCopy.isDeleted, isTrue);
  });

  test(
    'local-only delete flips only on caller and emits no wire traffic',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      await fixture.bobChatSDK.startChatSession();

      final aliceReceived = ChatTestHarness.awaitEvent<ChatMessageEvent>(
        fixture.aliceChatSDK,
      );
      await fixture.bobChatSDK.sendTextMessage('Hi Alice!');
      await aliceReceived;

      final bobMessage = (await fixture.bobChatSDK.messages).first as Message;

      final aliceTraffic = ChatTestHarness.collect(
        fixture.aliceChatSDK,
        duration: const Duration(seconds: 3),
      );

      await fixture.bobChatSDK.deleteMessage(bobMessage, localOnly: true);

      final emitted = await aliceTraffic;
      expect(
        emitted.where(
          (d) => d.chatItem is Message && (d.chatItem as Message).isDeleted,
        ),
        isEmpty,
        reason: 'Local-only delete must not broadcast a redaction',
      );

      final bobCopy =
          await fixture.bobChatSDK.getMessageById(bobMessage.messageId)
              as Message;
      expect(bobCopy.isDeletedLocally, isTrue);
      expect(bobCopy.isDeleted, isFalse);

      final aliceCopy = (await fixture.aliceChatSDK.messages).first as Message;
      expect(aliceCopy.isDeletedLocally, isFalse);
      expect(aliceCopy.isDeleted, isFalse);
    },
  );
}
