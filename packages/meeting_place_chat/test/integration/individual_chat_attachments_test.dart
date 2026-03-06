import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

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

    final attachments = [
      Attachment(
        id: const Uuid().v4(),
        description: 'Sample attachment',
        filename: 'attachment.jpeg',
        mediaType: AttachmentMediaType.imageJpeg.value,
        format: AttachmentFormat.imageSelfie.value,
        lastModifiedTime: DateTime.now().toUtc(),
        data: AttachmentData(
          base64:
              'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==',
        ),
        byteCount: 160,
      ),
    ];

    await fixture.aliceChatSDK.startChatSession();
    final message = await fixture.aliceChatSDK.sendTextMessage(
      'Hello World!',
      attachments: attachments,
    );

    final bobWaitForAttachments = Completer<List<Attachment>>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (!bobWaitForAttachments.isCompleted &&
            data.plainTextMessage?.type.toString() ==
                ChatProtocol.chatMessage.value &&
            message.messageId == data.plainTextMessage?.id) {
          stream.dispose();
          bobWaitForAttachments.complete(
            data.plainTextMessage?.attachments ?? [],
          );
        }
      });
    });

    final receivedAttachments = await bobWaitForAttachments.future;

    expect(receivedAttachments.first.toJson(), attachments.first.toJson());

    final bobMessages = await fixture.bobChatSDK.messages;
    expect(
      (bobMessages.first as Message).attachments.first.toJson(),
      attachments.first.toJson(),
    );

    final aliceMessages = await fixture.aliceChatSDK.messages;
    expect(
      (aliceMessages[0] as Message).attachments[0].toJson(),
      attachments[0].toJson(),
    );
  });
}
