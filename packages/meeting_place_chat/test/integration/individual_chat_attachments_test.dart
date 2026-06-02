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

  test('chat message attachments', () async {
    await fixture.bobChatSDK.startChatSession();

    final attachment = ChatAttachment(
      id: const Uuid().v4(),
      description: 'Sample attachment',
      filename: 'attachment.jpeg',
      mediaType: AttachmentMediaType.imageJpeg.value,
      format: AttachmentFormat.imageSelfie.value,
      lastModifiedTime: DateTime.now().toUtc(),
      data: ChatAttachmentData(
        base64:
            'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==',
      ),
      byteCount: 160,
    );

    await fixture.aliceChatSDK.startChatSession();
    final message = await fixture.aliceChatSDK.sendTextMessage(
      'Hello World!',
      attachment: attachment,
    );

    final receivedItem = await ChatTestHarness.awaitItem(
      fixture.bobChatSDK,
      where: (item) => item.messageId == message.messageId,
    );

    expect(
      (receivedItem as Message).attachments.first.toJson(),
      attachment.toJson(),
    );

    final bobMessages = await fixture.bobChatSDK.messages;
    expect(
      (bobMessages.first as Message).attachments.first.toJson(),
      attachment.toJson(),
    );

    final aliceMessages = await fixture.aliceChatSDK.messages;
    expect(
      (aliceMessages[0] as Message).attachments[0].toJson(),
      attachment.toJson(),
    );
  });
}
