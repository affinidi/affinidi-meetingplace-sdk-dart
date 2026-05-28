import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/didcomm/protocol.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import '../utils/sdk.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('sends chat presence message in configured interval', () async {
    final chatSDKWithReducedInterval = await initIndividualChatSDK(
      coreSDK: fixture.aliceSDK.coreSDK,
      did: fixture.aliceSDK.didDocument.id,
      otherPartyDid: fixture.bobSDK.didDocument.id,
      channelRepository: fixture.aliceSDK.channelRepository,
      options: ChatSDKOptions(
        chatPresenceSendInterval: const Duration(milliseconds: 200),
      ),
    );

    await fixture.bobChatSDK.startChatSession();

    final bobEvents = ChatTestHarness.collect(
      fixture.bobChatSDK,
      duration: const Duration(seconds: 3),
    );

    // Start SDK to send presence messages in interval
    await chatSDKWithReducedInterval.startChatSession();

    final presenceCount = (await bobEvents)
        .where((d) => d.event is ChatPresenceEvent)
        .length;
    expect(presenceCount, greaterThan(1));
    chatSDKWithReducedInterval.endChatSession();
  });

  test('start chat presence updates after restarting chat session', () async {
    late DateTime endChatSessionTime;
    final type = ChatProtocol.chatPresence.value;

    await fixture.bobChatSDK.startChatSession();
    final bobPresenceFromFirst = ChatTestHarness.awaitEvent<ChatPresenceEvent>(
      fixture.bobChatSDK,
    );

    // Start Alice's first chat session and wait for Bob to receive presence
    await fixture.aliceChatSDK.startChatSession();
    await bobPresenceFromFirst.timeout(const Duration(seconds: 10));

    // End chat session after receiving presence (outside of listener callback)
    fixture.aliceChatSDK.endChatSession();

    // Track time to verify that presence message received after
    // restarting chat session is new presence message and not a delayed
    // message from first session
    endChatSessionTime = DateTime.now().toUtc();

    // Delay to ensure that any presence message from first session that was
    // in flight is received before starting new session
    await Future<void>.delayed(const Duration(seconds: 1));

    // Start Alice's second chat session and check if Bob receives presence
    // message
    await fixture.aliceChatSDK.startChatSession();
    await Future<void>.delayed(const Duration(seconds: 3));

    final bobMessages = await fixture.bobSDK.coreSDK.didcomm.fetchMessages(
      did: fixture.bobSDK.didDocument.id,
      deleteOnRetrieve: true,
    );

    expect(
      bobMessages.any((MediatorMessage m) {
        if (m.plainTextMessage.isOfType(type) == false) {
          return false;
        }

        final message = ChatPresence.fromPlainTextMessage(m.plainTextMessage);
        return message.body.timestamp.isAfter(endChatSessionTime);
      }),
      isTrue,
    );
  });
}
