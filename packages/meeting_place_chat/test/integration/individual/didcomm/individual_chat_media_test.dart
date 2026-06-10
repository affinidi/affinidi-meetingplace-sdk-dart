import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

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

  test('sending reactions to other party', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobChat = ChatTestHarness.awaitEvent<ChatMessageEvent>(bobChatSDK);
    await aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobChat;

    final message = (await bobChatSDK.messages).first as Message;

    final aliceReactions = ChatTestHarness.collect(
      aliceChatSDK,
      duration: const Duration(seconds: 10),
    );

    await bobChatSDK.reactOnMessage(message, reaction: '👋');
    await bobChatSDK.reactOnMessage(message, reaction: '👍');
    await Future<void>.delayed(const Duration(seconds: 2));

    final twoReactionMessage =
        await aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(twoReactionMessage.reactions, equals(['👋', '👍']));

    await bobChatSDK.reactOnMessage(message, reaction: '👋');
    await aliceReactions;

    final updatedMessage =
        await aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(updatedMessage.reactions, equals(['👍']));
  });

  test(
    'media attachment is uploaded, decoded, and round-trips via downloadMedia',
    () async {
      const base64Image =
          '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==';
      final originalBytes = base64Decode(base64Image);

      final attachment = ChatAttachment(
        id: const Uuid().v4(),
        description: 'Sample attachment',
        filename: 'attachment.jpeg',
        mediaType: AttachmentMediaType.imageJpeg.value,
        lastModifiedTime: DateTime.now().toUtc(),
        data: ChatAttachmentData(base64: base64Image),
        byteCount: originalBytes.length,
      );

      await bobChatSDK.startChatSession();
      await aliceChatSDK.startChatSession();

      final bobItemFuture = ChatTestHarness.awaitItem(
        bobChatSDK,
        where: (item) =>
            item is Message &&
            item.attachments.isNotEmpty &&
            item.attachments.first.format == AttachmentFormat.hostedMedia.value,
      );

      final sentMessage = await aliceChatSDK.sendTextMessage(
        'Hello World!',
        attachments: [attachment],
      );

      final receivedItem = await bobItemFuture;

      final receivedMessage = receivedItem as Message;
      final receivedAttachment = receivedMessage.attachments.single;

      expect(receivedAttachment.format, AttachmentFormat.hostedMedia.value);
      expect(receivedAttachment.mediaType, attachment.mediaType);
      expect(receivedAttachment.filename, attachment.filename);
      expect(receivedAttachment.data, isNull);
      expect(receivedAttachment.transportId, isNotNull);
      expect(receivedMessage.transportId, isNotNull);
      expect(receivedMessage.value, 'Hello World!');

      final downloaded = await bobChatSDK.downloadMedia(receivedAttachment);
      expect(downloaded, originalBytes);

      expect(sentMessage.attachments.single.data, isNull);
      expect(sentMessage.attachments.single.transportId, isNotNull);
      expect(sentMessage.transportId, isNotNull);
    },
  );
}
