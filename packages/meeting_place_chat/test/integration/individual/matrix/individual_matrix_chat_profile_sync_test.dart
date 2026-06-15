@Tags(['serial'])
library;

import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../../utils/contact_card_fixture.dart' as fixtures;
import '../../utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;
  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  setUpAll(() async {
    fixture = await IndividualChatFixture.create(
      transport: ChannelTransport.matrix,
    );
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
    await runZonedGuarded(
      () async {
        await aliceChatSDK.endChatSession();
        await bobChatSDK.endChatSession();
      },
      (error, stackTrace) {
        if (error is StateError &&
            error.message.contains(
              'Cannot add new events after calling close',
            )) {
          return;
        }
        Zone.root.handleUncaughtError(error, stackTrace);
      },
    );
  });

  tearDownAll(() async {
    await fixture.dispose();
  });

  test(
    'Alice receives profile hash event when Bob starts chat with changed card',
    () async {
      await aliceChatSDK.startChatSession();

      final aliceProfileHash = ChatTestHarness.awaitEvent<ChatProfileHashEvent>(
        aliceChatSDK,
      );

      final channel = fixture.bobChannel;
      final contactCard = channel.contactCard!;
      contactCard.contactInfo['changed'] = 'value';
      await fixture.bobSDK.coreSDK.updateChannel(channel);

      await bobChatSDK.startChatSession();

      final received = await aliceProfileHash;
      expect(received, isA<ChatProfileHashEvent>());
    },
  );

  test('Alice does not send profile request if profile hash matches', () async {
    await aliceChatSDK.startChatSession();

    final aliceProfileHash = ChatTestHarness.awaitEvent<ChatProfileHashEvent>(
      aliceChatSDK,
    );

    final channel = fixture.bobChannel;
    final contactCard = channel.contactCard!;
    contactCard.contactInfo['changed'] = 'value';
    await fixture.bobSDK.coreSDK.updateChannel(channel);

    await bobChatSDK.startChatSession();

    final bobEvents = ChatTestHarness.collect(
      bobChatSDK,
      duration: const Duration(seconds: 5),
    );

    await aliceProfileHash;

    final bobReceivedProfileRequest = (await bobEvents)
        .map((d) => d.event)
        .whereType<ChatProfileRequestEvent>()
        .isNotEmpty;
    expect(bobReceivedProfileRequest, isFalse);
  });

  test(
    'Bob receives ConciergeMessage after Alice sends profile request',
    () async {
      await aliceChatSDK.startChatSession();
      await aliceChatSDK.chatStreamSubscription;

      final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
        did: fixture.bobSDK.didDocument.id,
        contactInfo: {'changed': 'value'},
      );

      final newBobChatSDK = await fixture.setup.createChatSdk(
        sdkInstance: fixture.bobSDK,
        channel: fixture.bobChannel,
        card: updatedCard,
      );

      final sessionFuture = newBobChatSDK.startChatSession();
      final bobProfileRequest =
          ChatTestHarness.awaitEvent<ChatProfileRequestEvent>(newBobChatSDK);

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
            aliceChatSDK,
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
}
