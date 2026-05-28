import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import '../utils/contact_card_fixture.dart' as fixtures;
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test(
    'alice receives profile hash message from Bob when Bob starts chat',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      final aliceProfileHash = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
        fixture.aliceChatSDK,
        where: (e) => e.type == ChatProtocol.chatAliasProfileHash.value,
      );

      final channel = await fixture.bobSDK.coreSDK.getChannelByDid(
        fixture.bobSDK.didDocument.id,
      );
      final contactCard = channel!.contactCard!;
      contactCard.contactInfo['changed'] = 'value';
      await fixture.bobSDK.coreSDK.updateChannel(channel);

      await fixture.bobChatSDK.startChatSession();
      final received = await aliceProfileHash;
      expect(received, isA<UnhandledChatEvent>());
    },
  );

  test('Alice does not send profile request if profile hash matches', () async {
    await fixture.aliceChatSDK.startChatSession();
    final aliceProfileHash = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
      fixture.aliceChatSDK,
      where: (e) => e.type == ChatProtocol.chatAliasProfileHash.value,
    );

    final channel = await fixture.bobSDK.coreSDK.getChannelByDid(
      fixture.bobSDK.didDocument.id,
    );
    final contactCard = channel!.contactCard!;
    contactCard.contactInfo['changed'] = 'value';
    await fixture.bobSDK.coreSDK.updateChannel(channel);

    await fixture.bobChatSDK.startChatSession();

    // Collect Bob's events for 3 seconds and verify no profile request fires.
    final bobEvents = ChatTestHarness.collect(
      fixture.bobChatSDK,
      duration: const Duration(seconds: 3),
    );

    await aliceProfileHash;

    final bobReceivedProfileRequest = (await bobEvents)
        .map((d) => d.event)
        .whereType<UnhandledChatEvent>()
        .any((e) => e.type == ChatProtocol.chatAliasProfileRequest.value);
    expect(bobReceivedProfileRequest, isFalse);
  });

  test(
    'Bob has concierge message after receiving profile hash requets',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
        did: fixture.bobSDK.didDocument.id,
        contactInfo: {'changed': 'value'},
      );

      // Ensure Alice's chat stream is initialised.
      await fixture.aliceChatSDK.chatStreamSubscription;

      final newBobChatSDK = await fixture.setup.createChatSdk(
        sdkInstance: fixture.bobSDK,
        otherPartySdkInstance: fixture.aliceSDK,
        card: updatedCard,
        channelCard: fixtures.ContactCardFixture.getContactCardFixture(
          did: fixture.bobSDK.didDocument.id,
          contactInfo: fixtures.ContactCardFixture.bobPrimaryCardInfo,
        ),
      );

      final bobChat = await newBobChatSDK.startChatSession();
      final bobProfileRequest = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
        newBobChatSDK,
        where: (e) => e.type == ChatProtocol.chatAliasProfileRequest.value,
      );

      await bobProfileRequest;

      final conciergeMessage =
          (await newBobChatSDK.messages).firstWhere(
                (chatItem) => chatItem.type == ChatItemType.conciergeMessage,
              )
              as ConciergeMessage;

      expect(conciergeMessage.isFromMe, false);
      expect(conciergeMessage.chatId, bobChat.id);
      expect(conciergeMessage.status, ChatItemStatus.userInput);
      expect(conciergeMessage.data, {
        'profileHash': updatedCard.profileHash,
        'replyTo': fixture.aliceSDK.didDocument.id,
      });

      final aliceMessage = ChatTestHarness.awaitEvent<ChatMessageEvent>(
        fixture.aliceChatSDK,
      );

      await newBobChatSDK.sendChatContactDetailsUpdate(conciergeMessage);

      await aliceMessage;
      final aliceChannel = await fixture.aliceSDK.coreSDK.getChannelByDid(
        fixture.bobSDK.didDocument.id,
      );
      expect(
        aliceChannel?.otherPartyContactCard?.contactInfo,
        equals(updatedCard.contactInfo),
      );

      newBobChatSDK.endChatSession();
    },
  );

  test('reject contact profile update', () async {
    await fixture.aliceChatSDK.startChatSession();
    final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
      did: fixture.bobSDK.didDocument.id,
      contactInfo: {'changed': 'value'},
    );

    await fixture.aliceChatSDK.chatStreamSubscription;

    final newBobChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.bobSDK,
      otherPartySdkInstance: fixture.aliceSDK,
      card: updatedCard,
      channelCard: fixtures.ContactCardFixture.getContactCardFixture(
        did: fixture.bobSDK.didDocument.id,
        contactInfo: fixtures.ContactCardFixture.bobPrimaryCardInfo,
      ),
    );

    await newBobChatSDK.startChatSession();
    final bobProfileRequest = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
      newBobChatSDK,
      where: (e) => e.type == ChatProtocol.chatAliasProfileRequest.value,
    );

    await bobProfileRequest;

    final conciergeMessage =
        (await newBobChatSDK.messages).firstWhere(
              (chatItem) => chatItem.type == ChatItemType.conciergeMessage,
            )
            as ConciergeMessage;

    await newBobChatSDK.rejectChatContactDetailsUpdate(conciergeMessage);
    expect(conciergeMessage.status, equals(ChatItemStatus.confirmed));

    newBobChatSDK.endChatSession();
  });
}
