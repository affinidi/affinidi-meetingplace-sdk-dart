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

  tearDown(() async {
    await fixture.dispose();
  });

  test('unhandled message is pushed to chat stream', () async {
    final bobChannelDid = fixture.bobChannel.permanentChannelDid!;
    final aliceChannelDid = fixture.aliceChannel.permanentChannelDid!;
    final unhandledMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://example.com/${const Uuid().v4()}'),
      from: bobChannelDid,
      to: [aliceChannelDid],
      body: {'text': 'Hello Alice!'},
    );

    await fixture.aliceChatSDK.startChatSession();
    final waitForUnhandled = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
      fixture.aliceChatSDK,
      where: (e) => e.type == unhandledMessage.type.toString(),
    );

    await fixture.bobSDK.coreSDK.sendMessage(
      DidCommOutgoingMessage(
        senderDid: bobChannelDid,
        recipientDid: aliceChannelDid,
        mediatorDid: fixture.bobChannel.mediatorDid,
        payload: unhandledMessage,
      ),
    );

    final received = await waitForUnhandled;
    expect(received.type, equals(unhandledMessage.type.toString()));
  });
}
