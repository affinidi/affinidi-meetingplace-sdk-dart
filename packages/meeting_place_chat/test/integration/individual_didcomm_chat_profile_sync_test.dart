// Profile-sync flow is currently DIDComm-only:
//   * `proposeProfileUpdate` on the matrix transport sends raw matrix events
//     (`com.affinidi.chat.profile-hash` / `profile-request`) that have no
//     translation back to `ChatProtocol.chatAlias*` URIs in the incoming
//     router.
//   * The matrix individual chat SDK has no concierge handler for
//     `profile-request`, so receivers don't persist a `ConciergeMessage` (only
//     the group flow does).
// Until the matrix transport implements an equivalent flow, this suite pins
// the channel transport to DIDComm.
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import '../utils/contact_card_fixture.dart' as fixtures;
import '../utils/didcomm_test_zone.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create(
      transport: ChannelTransport.didcomm,
    );
  });

  tearDown(() async {
    await fixture.dispose();
  });

  testWithDidcommGuard(
    'alice receives profile hash message from Bob when Bob starts chat',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      final aliceProfileHash = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
        fixture.aliceChatSDK,
        where: (e) => e.type == ChatProtocol.chatAliasProfileHash.value,
      );

      final channel = fixture.bobChannel;
      final contactCard = channel.contactCard!;
      contactCard.contactInfo['changed'] = 'value';
      await fixture.bobSDK.coreSDK.updateChannel(channel);

      await fixture.bobChatSDK.startChatSession();
      final received = await aliceProfileHash;
      expect(received, isA<UnhandledChatEvent>());
    },
  );

  testWithDidcommGuard(
    'Alice does not send profile request if profile hash matches',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      final aliceProfileHash = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
        fixture.aliceChatSDK,
        where: (e) => e.type == ChatProtocol.chatAliasProfileHash.value,
      );

      final channel = fixture.bobChannel;
      final contactCard = channel.contactCard!;
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
    },
  );

  testWithDidcommGuard(
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
        channel: fixture.bobChannel,
        card: updatedCard,
      );

      final sessionFuture = newBobChatSDK.startChatSession();
      final bobProfileRequest = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
        newBobChatSDK,
        where: (e) => e.type == ChatProtocol.chatAliasProfileRequest.value,
      );

      final bobChat = await sessionFuture;
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

      final aliceUpdate =
          ChatTestHarness.awaitEvent<ChatContactDetailsUpdateEvent>(
            fixture.aliceChatSDK,
          );

      await newBobChatSDK.sendChatContactDetailsUpdate(conciergeMessage);

      await aliceUpdate;
      final aliceChannel = await fixture.aliceSDK.coreSDK.getChannelByDid(
        fixture.aliceChannel.permanentChannelDid!,
      );
      expect(
        aliceChannel?.otherPartyContactCard?.contactInfo,
        equals(updatedCard.contactInfo),
      );

      await newBobChatSDK.endChatSession();
    },
  );

  testWithDidcommGuard('reject contact profile update', () async {
    await fixture.aliceChatSDK.startChatSession();
    final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
      did: fixture.bobSDK.didDocument.id,
      contactInfo: {'changed': 'value'},
    );

    await fixture.aliceChatSDK.chatStreamSubscription;

    final newBobChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.bobSDK,
      channel: fixture.bobChannel,
      card: updatedCard,
    );

    final sessionFuture = newBobChatSDK.startChatSession();
    final bobProfileRequest = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
      newBobChatSDK,
      where: (e) => e.type == ChatProtocol.chatAliasProfileRequest.value,
    );

    await sessionFuture;
    await bobProfileRequest;

    final conciergeMessage =
        (await newBobChatSDK.messages).firstWhere(
              (chatItem) => chatItem.type == ChatItemType.conciergeMessage,
            )
            as ConciergeMessage;

    await newBobChatSDK.rejectChatContactDetailsUpdate(conciergeMessage);
    expect(conciergeMessage.status, equals(ChatItemStatus.confirmed));

    await newBobChatSDK.endChatSession();
  });
}
