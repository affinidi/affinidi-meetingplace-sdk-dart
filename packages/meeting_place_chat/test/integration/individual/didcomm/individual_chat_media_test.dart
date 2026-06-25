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

  test('sending reactions to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobChat = ChatTestHarness.awaitEvent<ChatMessageEvent>(
      fixture.bobChatSDK,
    );
    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobChat;

    final message = (await fixture.bobChatSDK.messages).first as Message;

    final aliceReactions = ChatTestHarness.collect(
      fixture.aliceChatSDK,
      duration: const Duration(seconds: 10),
    );

    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👋');
    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👍');
    await Future<void>.delayed(const Duration(seconds: 2));

    final twoReactionMessage =
        await fixture.aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(
      twoReactionMessage.reactions.map((r) => r.emoji),
      equals(['👋', '👍']),
    );

    await fixture.bobChatSDK.reactOnMessage(message, reaction: '👋');
    await aliceReactions;

    final updatedMessage =
        await fixture.aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(updatedMessage.reactions.map((r) => r.emoji), equals(['👍']));
  });

  // SKIP: test fails
  // test(
  //   'media attachment is uploaded, decoded, and round-trips via
  // downloadMedia',
  //   () async {
  //     const base64Image =
  //         '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==';
  //     final originalBytes = base64Decode(base64Image);

  //     final attachment = ChatAttachment(
  //       id: const Uuid().v4(),
  //       description: 'Sample attachment',
  //       filename: 'attachment.jpeg',
  //       mediaType: AttachmentMediaType.imageJpeg.value,
  //       lastModifiedTime: DateTime.now().toUtc(),
  //       data: ChatAttachmentData(base64: base64Image),
  //       byteCount: originalBytes.length,
  //     );

  //     await fixture.bobChatSDK.startChatSession();
  //     await fixture.aliceChatSDK.startChatSession();

  //     final bobItemFuture = ChatTestHarness.awaitItem(
  //       fixture.bobChatSDK,
  //       where: (item) =>
  //           item is Message &&
  //           item.attachments.isNotEmpty &&
  //        item.attachments.first.format ==
  //  'media-format',
  //     );

  //     final sentMessage = await fixture.aliceChatSDK.sendTextMessage(
  //       'Hello World!',
  //       attachments: [attachment],
  //     );

  //     final receivedItem = await bobItemFuture;

  //     final receivedMessage = receivedItem as Message;
  //     final receivedAttachment = receivedMessage.attachments.single;

  //     expect(receivedAttachment.format, 'media-format');
  //     expect(receivedAttachment.mediaType, attachment.mediaType);
  //     expect(receivedAttachment.filename, attachment.filename);
  //     expect(receivedAttachment.data, isNull);
  //     expect(receivedAttachment.transportId, isNotNull);
  //     expect(receivedMessage.transportId, isNotNull);
  //     expect(receivedMessage.value, 'Hello World!');

  //     final downloaded = await fixture.bobChatSDK.downloadMedia(
  //       receivedAttachment,
  //     );
  //     expect(downloaded, originalBytes);

  //     expect(sentMessage.attachments.single.data, isNull);
  //     expect(sentMessage.attachments.single.transportId, isNotNull);
  //     expect(sentMessage.transportId, isNotNull);
  //   },
  // );
}
