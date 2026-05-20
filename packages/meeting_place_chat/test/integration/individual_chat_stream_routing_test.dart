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

  test('unhandled message is pushed to chat stream', () async {
    final unhandledMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://example.com/${const Uuid().v4()}'),
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

  test('incoming VDIP issued-credential is dispatched to coreSDK.vdip,'
      ' not chatStream', () async {
    final vdipMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse(VdipClient.issuedCredentialMessageType),
      from: fixture.bobSDK.didDocument.id,
      to: [fixture.aliceSDK.didDocument.id],
      body: {'credential': '{}', 'credential_format': 'w3c/ldv1'},
    );

    final dispatchedToVdip = Completer<PlainTextMessage>();
    var receivedOnChatStream = false;

    await fixture.aliceChatSDK.startChatSession();

    // Listen on coreSDK.vdip.incomingMessages to confirm dispatch
    final vdipSub = fixture.aliceSDK.coreSDK.vdip.incomingMessages.listen((
      msg,
    ) {
      if (msg.id == vdipMessage.id) dispatchedToVdip.complete(msg);
    });

    // Listen on chatStream to confirm it is NOT pushed there
    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.id == vdipMessage.id) {
          receivedOnChatStream = true;
        }
      });
    });

    await fixture.bobSDK.coreSDK.sendMessage(
      vdipMessage,
      senderDid: fixture.bobSDK.didDocument.id,
      recipientDid: fixture.aliceSDK.didDocument.id,
    );

    final dispatched = await dispatchedToVdip.future.timeout(
      const Duration(seconds: 10),
    );

    await vdipSub.cancel();

    expect(dispatched.id, equals(vdipMessage.id));
    expect(
      receivedOnChatStream,
      isFalse,
      reason: 'VDIP messages must not be pushed to the chat stream',
    );
  });
}
