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

  test('sendEffect delivers ChatEffectEvent to other party', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobEffect = ChatTestHarness.awaitEvent<ChatEffectEvent>(
      bobChatSDK,
      where: (e) => e.effectName == Effect.confetti.name,
    );

    await aliceChatSDK.sendEffect(Effect.confetti);

    final received = await bobEffect;
    expect(received.effectName, equals(Effect.confetti.name));
  });

  test('sendCustomEvent delivers message to other party', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    await bobChatSDK.chatStreamSubscription;
    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(bobChatSDK);

    await aliceChatSDK.sendCustomEvent(
      type: ChatProtocol.chatMessage.value,
      payload: {
        'text': 'Hello via sendCustomEvent',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await bobWait;
    final received = (await bobChatSDK.messages).first as Message;
    expect(received.value, equals('Hello via sendCustomEvent'));
    expect(
      received.senderDid,
      equals(fixture.aliceChannel.permanentChannelDid),
    );
  });

  test('sendCustomEvent message is persisted in repository', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(bobChatSDK);

    await aliceChatSDK.sendCustomEvent(
      type: ChatProtocol.chatMessage.value,
      payload: {
        'text': 'Persist test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await bobWait;
    final received = (await bobChatSDK.messages).first as Message;
    expect(received.value, equals('Persist test'));
    expect(
      received.senderDid,
      equals(fixture.aliceChannel.permanentChannelDid),
    );

    final bobMessages = await bobChatSDK.messages;
    expect(
      bobMessages.whereType<Message>().any((m) => m.value == 'Persist test'),
      isTrue,
      reason: 'Message should be persisted in Bob\'s repository',
    );
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

    await aliceChatSDK.startChatSession();
    final waitForUnhandled = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
      aliceChatSDK,
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
