import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
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

  test('unhandled message is pushed to chat stream', () async {
    final unhandledMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://example.com/${Uuid().v4()}'),
      from: fixture.bobSDK.didDocument.id,
      to: [fixture.aliceSDK.didDocument.id],
      body: {'text': 'Hello Alice!'},
    );

    final pushedToChatStream = Completer<StreamData>();

    await fixture.aliceChatSDK.startChatSession();
    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) async {
        if (message.plainTextMessage?.type == unhandledMessage.type) {
          pushedToChatStream.complete(message);
          stream.dispose();
        }
      });
    });

    await fixture.bobSDK.coreSDK.sendMessage(
      unhandledMessage,
      senderDid: fixture.bobSDK.didDocument.id,
      recipientDid: fixture.aliceSDK.didDocument.id,
    );

    final receivedStreamData = await pushedToChatStream.future.timeout(
      const Duration(seconds: 10),
    );

    expect(receivedStreamData, isA<StreamData>());
    expect(
      receivedStreamData.plainTextMessage?.id,
      equals(unhandledMessage.id),
    );
  });
}
