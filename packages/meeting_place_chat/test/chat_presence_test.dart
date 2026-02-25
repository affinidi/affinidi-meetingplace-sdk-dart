import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
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
}
