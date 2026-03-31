import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

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

    var receivedMessages = 0;
    await fixture.bobChatSDK.startChatSession();

    // Consume chat presence messages
    final waitForSubscription = Completer<void>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      waitForSubscription.complete();
      stream!.listen((data) {
        if (MessageUtils.isType(
          data.plainTextMessage!,
          ChatProtocol.chatPresence,
        )) {
          receivedMessages += 1;
        }
      });
    });

    // Start SDK to send presence messages in interval
    await chatSDKWithReducedInterval.startChatSession();

    await waitForSubscription.future;
    await Future<void>.delayed(const Duration(seconds: 3));

    expect(receivedMessages, greaterThan(1));
    chatSDKWithReducedInterval.endChatSession();
  });

  test('start chat presence updates after restarting chat session', () async {
    late DateTime endChatSessionTime;

    final bobReceivedPresenceFromFirstSession = Completer<void>();
    final type = ChatProtocol.chatPresence.value;

    await fixture.bobChatSDK.startChatSession();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.isOfType(type) == true) {
          if (!bobReceivedPresenceFromFirstSession.isCompleted) {
            bobReceivedPresenceFromFirstSession.complete();
          }
        }
      });
    });

    // Start Alice's first chat session and wait for Bob to receive presence
    await fixture.aliceChatSDK.startChatSession();
    await bobReceivedPresenceFromFirstSession.future.timeout(
      const Duration(seconds: 10),
    );

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

    final bobMessages = await fixture.bobSDK.coreSDK.fetchMessages(
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
