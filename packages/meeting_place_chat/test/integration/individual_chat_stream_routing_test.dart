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

  test('unhandled message is pushed to chat stream', () async {
    final unhandledMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://example.com/${const Uuid().v4()}'),
      from: fixture.bobSDK.didDocument.id,
      to: [fixture.aliceSDK.didDocument.id],
      body: {'text': 'Hello Alice!'},
    );

    await fixture.aliceChatSDK.startChatSession();
    final waitForUnhandled = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
      fixture.aliceChatSDK,
      where: (e) => e.type == unhandledMessage.type.toString(),
    );

    await fixture.bobSDK.coreSDK.sendMessage(
      DidCommOutgoingMessage(
        senderDid: fixture.bobSDK.didDocument.id,
        recipientDid: fixture.aliceSDK.didDocument.id,
        payload: unhandledMessage,
      ),
    );

    final received = await waitForUnhandled;
    expect(received.type, equals(unhandledMessage.type.toString()));
  });
}
