import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'utils/contact_card_fixture.dart' as fixtures;
import 'utils/sdk.dart';
import 'utils/setup_chat_sdk.dart';

void main() async {
  final setup = SetupChatSdk();

  late SDKInstance alice;
  late SDKInstance bob;

  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  setUp(() async {
    alice = await setup.createCoreSDK(
      fixtures.ContactCardFixture.alicePrimaryCardInfo,
    );

    bob = await setup.createCoreSDK(
      fixtures.ContactCardFixture.bobPrimaryCardInfo,
    );

    aliceChatSDK = await setup.createChatSdk(
      sdkInstance: alice,
      otherPartySdkInstance: bob,
    );

    bobChatSDK = await setup.createChatSdk(
      sdkInstance: bob,
      otherPartySdkInstance: alice,
    );
  });

  test('sends chat presence message in configured interval', () async {
    final chatSDKWithReducedInterval = await initIndividualChatSDK(
      coreSDK: alice.coreSDK,
      did: alice.didDocument.id,
      otherPartyDid: bob.didDocument.id,
      channelRepository: alice.channelRepository,
      options: ChatSDKOptions(
        chatPresenceSendInterval: const Duration(seconds: 1),
      ),
    );

    var receivedMessages = 0;
    await bobChatSDK.startChatSession();

    // Consume chat presence messages
    final waitForSubscription = Completer<void>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
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
  });

  test('start chat presence updates after restarting chat session', () async {
    late DateTime endChatSessionTime;

    final bobReceivedPresenceFromFirstSession = Completer<void>();
    final type = ChatProtocol.chatPresence.value;

    await bobChatSDK.startChatSession();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.isOfType(type) == true) {
          if (!bobReceivedPresenceFromFirstSession.isCompleted) {
            bobReceivedPresenceFromFirstSession.complete();
            aliceChatSDK.endChatSession();

            // Track time to verify that presence message received after
            // restarting chat session is new presence message and not a delayed
            // message from first session
            endChatSessionTime = DateTime.now();
          }
        }
      });
    });

    // Start Alice's first chat session and end chat session after Bob received
    await aliceChatSDK.startChatSession();
    await bobReceivedPresenceFromFirstSession.future.timeout(
      const Duration(seconds: 10),
    );

    // Start Alice's second chat session and check if Bob receives presence
    // message
    await aliceChatSDK.startChatSession();
    await Future.delayed(const Duration(seconds: 3));

    final bobMessages = await bob.coreSDK.fetchMessages(
      did: bob.didDocument.id,
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
