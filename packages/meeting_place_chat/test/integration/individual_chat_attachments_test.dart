import 'dart:convert';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

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

      await fixture.bobChatSDK.startChatSession();
      await fixture.aliceChatSDK.startChatSession();

      final sentMessage = await fixture.aliceChatSDK.sendTextMessage(
        'Hello World!',
        attachments: [attachment],
      );

      final receivedItem = await ChatTestHarness.awaitItem(
        fixture.bobChatSDK,
        where: (item) =>
            item is Message &&
            item.attachments.isNotEmpty &&
            item.attachments.first.format ==
                AttachmentFormat.hostedMedia.value,
      );

      final receivedMessage = receivedItem as Message;
      final receivedAttachment = receivedMessage.attachments.single;

      // Display-only metadata: mxc URI and encryption JSON are stripped on the
      // SDK boundary; per-attachment transportId is the only reference.
      expect(receivedAttachment.format, AttachmentFormat.hostedMedia.value);
      expect(receivedAttachment.mediaType, attachment.mediaType);
      expect(receivedAttachment.filename, attachment.filename);
      expect(receivedAttachment.data, isNull);
      expect(receivedAttachment.transportId, isNotNull);
      expect(receivedMessage.transportId, isNotNull);
      expect(receivedMessage.value, 'Hello World!');

      final downloaded = await fixture.bobChatSDK.downloadMedia(
        receivedAttachment,
      );
      expect(downloaded, originalBytes);

      // Sender side mirrors: stored attachment carries display metadata only,
      // transportId is set after the matrix event is acknowledged.
      expect(sentMessage.attachments.single.data, isNull);
      expect(sentMessage.attachments.single.transportId, isNotNull);
      expect(sentMessage.transportId, isNotNull);
    },
  );
}
