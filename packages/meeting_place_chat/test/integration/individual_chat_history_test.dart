import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/contact_card_fixture.dart' as fixtures;
import '../utils/setup_chat_sdk.dart';
import '../utils/storage/in_memory_storage.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('chat history resumes and is chat-scoped', () async {
    final bobChatCompleted = Completer<void>();
    await fixture.bobChatSDK.startChatSession();

    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (!bobChatCompleted.isCompleted && data.event is ChatMessageEvent) {
          bobChatCompleted.complete();
        }
      });
    });

    final aliceDelivered = Completer<void>();
    await fixture.aliceChatSDK.startChatSession();

    await fixture.aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        final event = data.event;
        if (!aliceDelivered.isCompleted &&
            event is UnhandledChatEvent &&
            event.type == ChatProtocol.chatDelivered.value) {
          aliceDelivered.complete();
        }
      });
    });

    await fixture.aliceChatSDK.sendTextMessage('Hello World!');
    await aliceDelivered.future;

    fixture.aliceChatSDK.endChatSession();

    // On resume Alice will receive her chat history
    await fixture.aliceChatSDK.startChatSession();
    expect((await fixture.aliceChatSDK.messages).length, equals(1));
    fixture.aliceChatSDK.endChatSession();

    // Different chat -> history should be empty
    final setup = SetupChatSdk();
    final charlieSDK = await setup.createCoreSDK(
      fixtures.ContactCardFixture.charliePrimaryCardInfo,
    );

    // Keep behaviour aligned with original test setup: create a reciprocal
    // Alice-channel on Charlie's repository.
    await charlieSDK.channelRepository.createChannel(
      Channel(
        offerLink: 'charlie',
        publishOfferDid: '',
        mediatorDid: '',
        permanentChannelDid: charlieSDK.didDocument.id,
        otherPartyPermanentChannelDid: fixture.aliceSDK.didDocument.id,
        status: ChannelStatus.inaugurated,
        type: ChannelType.individual,
        isConnectionInitiator: false,
        contactCard: charlieSDK.contactCard,
        otherPartyContactCard: fixture.aliceSDK.contactCard,
      ),
    );

    final aliceChatWithCharlie = await setup.createChatSdk(
      sdkInstance: fixture.aliceSDK,
      otherPartySdkInstance: charlieSDK,
    );

    await aliceChatWithCharlie.startChatSession();
    expect((await aliceChatWithCharlie.messages).length, isZero);
    aliceChatWithCharlie.endChatSession();

    await bobChatCompleted.future;
    expect((await fixture.bobChatSDK.messages).length, equals(1));
  });

  test('returns new messages from mediator', () async {
    final bobChat = await fixture.bobChatSDK.startChatSession();
    expect(bobChat.messages.length, equals(0));
    fixture.bobChatSDK.endChatSession();

    await fixture.aliceChatSDK.sendTextMessage('Hello Bob!');
    await fixture.bobChatSDK.startChatSession();

    final completer = Completer<Message>();
    await fixture.bobChatSDK.chatStreamSubscription.then(
      (stream) => {
        stream!.listen((data) {
          if (data.event is ChatMessageEvent && !completer.isCompleted) {
            completer.complete(data.chatItem as Message);
          }
        }),
      },
    );

    final actual = await completer.future;
    expect(actual.value, equals('Hello Bob!'));
  });

  test(
    'keeps message history if new chat SDK instance is initialized',
    () async {
      final storage = InMemoryStorage();
      final setup = SetupChatSdk();

      final chatSDK = await setup.createChatSdk(
        sdkInstance: fixture.aliceSDK,
        otherPartySdkInstance: fixture.bobSDK,
        storage: storage,
      );

      await chatSDK.sendTextMessage('Hello World!');
      expect((await chatSDK.messages).length, equals(1));
      chatSDK.endChatSession();

      final chatSDKNewInstance = await setup.createChatSdk(
        sdkInstance: fixture.aliceSDK,
        otherPartySdkInstance: fixture.bobSDK,
        storage: storage,
      );

      expect((await chatSDKNewInstance.messages).length, equals(1));
      chatSDKNewInstance.endChatSession();
    },
  );
}
