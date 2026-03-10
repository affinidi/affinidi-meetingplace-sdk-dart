import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

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

      final waitForProfileHashMessage = Completer<bool>();
      await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
        stream!.listen((message) {
          if (message.plainTextMessage?.type.toString() ==
              ChatProtocol.chatAliasProfileHash.value) {
            if (!waitForProfileHashMessage.isCompleted) {
              waitForProfileHashMessage.complete(true);
            }
          }
        });
      });

      final channel = await fixture.bobSDK.coreSDK.getChannelByDid(
        fixture.bobSDK.didDocument.id,
      );
      final contactCard = channel!.contactCard!;
      contactCard.contactInfo['changed'] = 'value';
      await fixture.bobSDK.coreSDK.updateChannel(channel);

      await fixture.bobChatSDK.startChatSession();
      final receivedProfileHashMessage = await waitForProfileHashMessage.future;
      expect(receivedProfileHashMessage, isTrue);
    },
  );

  test('Alice does not send profile request if profile hash matches', () async {
    await fixture.aliceChatSDK.startChatSession();
    final aliceCompleter = Completer<void>();

    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatAliasProfileHash.value) {
          if (!aliceCompleter.isCompleted) aliceCompleter.complete();
        }
      });
    });

    final channel = await fixture.bobSDK.coreSDK.getChannelByDid(
      fixture.bobSDK.didDocument.id,
    );
    final contactCard = channel!.contactCard!;
    contactCard.contactInfo['changed'] = 'value';
    await fixture.bobSDK.coreSDK.updateChannel(channel);

    await fixture.bobChatSDK.startChatSession();

    var receivedProfileRequestMessage = false;
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatAliasProfileRequest.value) {
          receivedProfileRequestMessage = true;
        }
      });
    });

    await aliceCompleter.future;
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(receivedProfileRequestMessage, isFalse);
  });

  test(
    'Bob has concierge message after receiving profile hash requets',
    () async {
      await fixture.aliceChatSDK.startChatSession();
      final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
        did: fixture.bobSDK.didDocument.id,
        contactInfo: {'changed': 'value'},
      );

      final aliceOpenedChat = Completer<void>();
      await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
        aliceOpenedChat.complete();
      });

      await aliceOpenedChat.future;

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
      final bobProfileRequestCompleter = Completer<void>();
      await newBobChatSDK.chatStreamSubscription.then((stream) {
        stream!.listen((message) {
          if (message.plainTextMessage?.type.toString() ==
              ChatProtocol.chatAliasProfileRequest.value) {
            if (bobProfileRequestCompleter.isCompleted) return;
            bobProfileRequestCompleter.complete();
          }
        });
      });

      await newBobChatSDK.sendProfileHash();
      await bobProfileRequestCompleter.future;

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

      final aliceChatCompleter = Completer<void>();
      await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
        stream!.listen((message) async {
          if (message.plainTextMessage?.type.toString() ==
              ChatProtocol.chatContactDetailsUpdate.value) {
            aliceChatCompleter.complete();
          }
        });
      });

      await newBobChatSDK.sendChatContactDetailsUpdate(conciergeMessage);

      await aliceChatCompleter.future;
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

    final aliceOpenedChat = Completer<void>();
    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      aliceOpenedChat.complete();
    });

    await aliceOpenedChat.future;

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
    final bobProfileRequestCompleter = Completer<void>();
    await newBobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatAliasProfileRequest.value) {
          if (bobProfileRequestCompleter.isCompleted) return;
          bobProfileRequestCompleter.complete();
        }
      });
    });

    await newBobChatSDK.sendProfileHash();
    await bobProfileRequestCompleter.future;

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
