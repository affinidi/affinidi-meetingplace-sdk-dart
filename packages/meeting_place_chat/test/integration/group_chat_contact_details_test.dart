import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../utils/chat_test_harness.dart';
import '../utils/contact_card_fixture.dart';
import '../utils/sdk.dart';
import 'utils/group_chat_fixture.dart';

void main() {
  late GroupChatFixture fixture;

  setUp(() async {
    fixture = await GroupChatFixture.create();
  });

  tearDown(() {
    fixture.disposeSessions();
  });

  test(
    'sendChatContactDetailsUpdate broadcasts ChatContactDetailsUpdateEvent',
    () async {
      final updatedCard = ContactCardFixture.getContactCardFixture(
        did: fixture.bobMemberDid,
        contactInfo: {
          'n': {'given': 'Bob', 'surname': 'Updated'},
        },
      );

      final newBobChatSDK = await initGroupChatSDK(
        coreSDK: fixture.bobSDK,
        did: fixture.bobMemberDid,
        otherPartyDid:
            fixture.publishOfferResult.connectionOffer.groupDid!,
        group: fixture.bobGroup,
        channelRepository: fixture.bobChannelRepository,
        card: updatedCard,
      );

      await fixture.aliceChatSDK.startChatSession();
      await fixture.charlieChatSDK.startChatSession();
      final bobChat = await newBobChatSDK.startChatSession();

      final aliceUpdate =
          ChatTestHarness.awaitEvent<ChatContactDetailsUpdateEvent>(
        fixture.aliceChatSDK,
        where: (e) => e.senderDid == fixture.bobMemberDid,
      );
      final charlieUpdate =
          ChatTestHarness.awaitEvent<ChatContactDetailsUpdateEvent>(
        fixture.charlieChatSDK,
        where: (e) => e.senderDid == fixture.bobMemberDid,
      );

      final concierge = ConciergeMessage(
        chatId: bobChat.id,
        messageId: const Uuid().v4(),
        senderDid: fixture.bobMemberDid,
        isFromMe: true,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.userInput,
        conciergeType: ConciergeMessageType.permissionToUpdateProfile,
        data: const {},
      );

      await newBobChatSDK.sendChatContactDetailsUpdate(concierge);

      final aliceEvent = await aliceUpdate;
      final charlieEvent = await charlieUpdate;

      expect(
        aliceEvent.contactCard.contactInfo,
        equals(updatedCard.contactInfo),
      );
      expect(
        charlieEvent.contactCard.contactInfo,
        equals(updatedCard.contactInfo),
      );

      newBobChatSDK.endChatSession();
    },
  );
}
