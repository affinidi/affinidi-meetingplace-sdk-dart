import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('sends chat presence message in configured interval', () async {
    final chatSDKWithReducedInterval = await fixture.setup.createChatSdk(
      sdkInstance: fixture.aliceSDK,
      channel: fixture.aliceChannel,
      options: MeetingPlaceChatSDKOptions(
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
    await chatSDKWithReducedInterval.endChatSession();
  });

  test('start chat presence updates after restarting chat session', () async {
    // The didcomm 2.3.3 mediator client races its connection-close against an
    // unawaited fetch loop that keeps adding to a now-closed StreamController.
    // This surfaces as an unhandled "Cannot add new events after calling
    // close" StateError during Alice's endChatSession() and is unrelated to
    // the behaviour under test. Swallow it so the test reflects only the
    // presence-restart logic. See connection.dart#start vs #stop in didcomm.
    await runZonedGuarded(
      () async {
        await fixture.bobChatSDK.startChatSession();
        await fixture.bobChatSDK.chatStreamSubscription;

        final bobPresenceFromFirst =
            ChatTestHarness.awaitEvent<ChatPresenceEvent>(fixture.bobChatSDK);

        // Start Alice's first chat session and wait for Bob to receive presence
        await fixture.aliceChatSDK.startChatSession();
        await bobPresenceFromFirst.timeout(const Duration(seconds: 10));

        // End chat session after receiving presence (outside listener callback)
        await fixture.aliceChatSDK.endChatSession();

        // Track time to verify that presence message received after restarting
        // chat session is a new presence message and not a delayed message
        // from the first session.
        final endChatSessionTime = DateTime.now().toUtc();

        // Arm the wait BEFORE the second session starts so the first presence
        // produced by the second session is not missed.
        final bobPresenceFromSecond =
            ChatTestHarness.awaitEvent<ChatPresenceEvent>(
              fixture.bobChatSDK,
              where: (e) => e.timestamp.isAfter(endChatSessionTime),
              timeout: const Duration(seconds: 10),
            );

        // Delay to ensure that any in-flight presence message from the first
        // session is received before starting the new session.
        await Future<void>.delayed(const Duration(seconds: 1));

        // Start Alice's second chat session and verify Bob receives a fresh
        // presence message whose timestamp is after the end of the first
        // session.
        await fixture.aliceChatSDK.startChatSession();

        final received = await bobPresenceFromSecond;
        expect(received.timestamp.isAfter(endChatSessionTime), isTrue);
      },
      (error, stackTrace) {
        if (error is StateError &&
            error.message.contains(
              'Cannot add new events after calling close',
            )) {
          return;
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  });
}
