import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/chat_test_harness.dart';
import '../../../utils/didcomm_test_zone.dart';
import '../../utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;
  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  setUpAll(() async {
    fixture = await IndividualChatFixture.create();
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

  group('messaging', () {
    testWithDidcommGuard(
      'sendEffect delivers ChatEffectEvent to other party',
      () async {
        await aliceChatSDK.startChatSession();
        await bobChatSDK.startChatSession();

        final bobEffect = ChatTestHarness.awaitEvent<ChatEffectEvent>(
          bobChatSDK,
          where: (e) => e.effectName == Effect.confetti.name,
        );

        await aliceChatSDK.sendEffect(Effect.confetti);

        final received = await bobEffect;
        expect(received.effectName, equals(Effect.confetti.name));
      },
    );

    testWithDidcommGuard(
      'sendCustomEvent delivers message to other party',
      () async {
        await aliceChatSDK.startChatSession();
        await bobChatSDK.startChatSession();

        await bobChatSDK.chatStreamSubscription;
        final bobWait = ChatTestHarness.awaitEvent<ChatMessageEvent>(
          bobChatSDK,
        );

        await aliceChatSDK.sendCustomEvent(
          type: ChatProtocol.chatMessage.value,
          payload: {
            'text': 'Hello via sendCustomEvent',
            'seq_no': 1,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        );

        await bobWait;
        final received = (await bobChatSDK.messages).first as Message;
        expect(received.value, equals('Hello via sendCustomEvent'));
        expect(
          received.senderDid,
          equals(fixture.aliceChannel.permanentChannelDid),
        );
      },
    );

    testWithDidcommGuard(
      'unhandled message is pushed to chat stream',
      () async {
        final bobChannelDid = fixture.bobChannel.permanentChannelDid!;
        final aliceChannelDid = fixture.aliceChannel.permanentChannelDid!;
        final unhandledMessage = PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse('https://example.com/${const Uuid().v4()}'),
          from: bobChannelDid,
          to: [aliceChannelDid],
          body: {'text': 'Hello Alice!'},
        );

        await aliceChatSDK.startChatSession();
        final waitForUnhandled = ChatTestHarness.awaitEvent<UnhandledChatEvent>(
          aliceChatSDK,
          where: (e) => e.type == unhandledMessage.type.toString(),
        );

        await fixture.bobSDK.coreSDK.sendMessage(
          DidCommOutgoingMessage(
            senderDid: bobChannelDid,
            recipientDid: aliceChannelDid,
            mediatorDid: fixture.bobChannel.mediatorDid,
            payload: unhandledMessage,
          ),
        );

        final received = await waitForUnhandled;
        expect(received.type, equals(unhandledMessage.type.toString()));
      },
    );
  });

  group('delivery', () {
    testWithDidcommGuard('alice sends multiple messages', () async {
      await aliceChatSDK.startChatSession();
      await bobChatSDK.startChatSession();

      final bobReceivedTwo = ChatTestHarness.collect(
        bobChatSDK,
        duration: const Duration(seconds: 10),
      );

      final messageIds = <String>[
        (await aliceChatSDK.sendTextMessage('Message#1')).messageId,
        (await aliceChatSDK.sendTextMessage('Message#2')).messageId,
      ];

      final aliceDelivered = ChatTestHarness.collect(
        aliceChatSDK,
        duration: const Duration(seconds: 10),
      );

      final bobMessageIds = (await bobReceivedTwo)
          .where((d) => d.event is ChatMessageEvent && d.chatItem != null)
          .map((d) => d.chatItem!.messageId)
          .toSet();
      expect(bobMessageIds, containsAll(messageIds));

      final deliveredIds = (await aliceDelivered)
          .map((d) => d.event)
          .whereType<ChatMessageDeliveredEvent>()
          .expand((e) => e.messageIds)
          .toSet();
      expect(deliveredIds, containsAll(messageIds));

      final aliceRepositoryMessages = await aliceChatSDK.messages;
      final aliceSentMessages = aliceRepositoryMessages
          .where((m) => messageIds.contains(m.messageId))
          .toList();
      expect(aliceSentMessages.length, equals(2));
      expect(aliceSentMessages[0].status, ChatItemStatus.delivered);
      expect(aliceSentMessages[1].status, ChatItemStatus.delivered);

      final bobRepositoryMessages = await bobChatSDK.messages;
      final bobReceivedMessages = bobRepositoryMessages
          .where((m) => messageIds.contains(m.messageId))
          .toList();
      expect(bobReceivedMessages.length, equals(2));
      expect(bobReceivedMessages[0].status, ChatItemStatus.received);
      expect(bobReceivedMessages[1].status, ChatItemStatus.received);
    });

    testWithDidcommGuard(
      'replayed history rolls all buffered outbound messages to delivered',
      () async {
        await aliceChatSDK.startChatSession();

        final sentIds = <String>[
          (await aliceChatSDK.sendTextMessage('Buffered #1')).messageId,
          (await aliceChatSDK.sendTextMessage('Buffered #2')).messageId,
        ];

        final aliceFirstDelivered = ChatTestHarness.awaitItem(
          aliceChatSDK,
          where: (item) =>
              item is Message &&
              item.messageId == sentIds.first &&
              item.status == ChatItemStatus.delivered,
        );

        final aliceLastDelivered = ChatTestHarness.awaitItem(
          aliceChatSDK,
          where: (item) =>
              item is Message &&
              item.messageId == sentIds.last &&
              item.status == ChatItemStatus.delivered,
        );

        await bobChatSDK.startChatSession();
        await aliceFirstDelivered;
        await aliceLastDelivered;

        final aliceMessages = await aliceChatSDK.messages;
        final byId = {
          for (final m in aliceMessages.cast<Message>()) m.messageId: m,
        };
        for (final id in sentIds) {
          expect(byId[id]?.status, ChatItemStatus.delivered, reason: 'id=$id');
        }
      },
    );
  });

  group('presence', () {
    testWithDidcommGuard(
      'sends chat presence message in configured interval',
      () async {
        final chatSDKWithReducedInterval = await fixture.setup.createChatSdk(
          sdkInstance: fixture.aliceSDK,
          channel: fixture.aliceChannel,
          options: MeetingPlaceChatSDKOptions(
            chatPresenceSendInterval: const Duration(milliseconds: 200),
          ),
        );

        await bobChatSDK.startChatSession();

        final bobEvents = ChatTestHarness.collect(
          bobChatSDK,
          duration: const Duration(seconds: 3),
        );

        await chatSDKWithReducedInterval.startChatSession();

        final presenceCount = (await bobEvents)
            .where((d) => d.event is ChatPresenceEvent)
            .length;
        expect(presenceCount, greaterThan(1));
        await chatSDKWithReducedInterval.endChatSession();
      },
    );

    testWithDidcommGuard(
      'start chat presence updates after restarting chat session',
      () async {
        await bobChatSDK.startChatSession();
        await bobChatSDK.chatStreamSubscription;

        final bobPresenceFromFirst =
            ChatTestHarness.awaitEvent<ChatPresenceEvent>(bobChatSDK);

        await aliceChatSDK.startChatSession();
        await bobPresenceFromFirst.timeout(const Duration(seconds: 10));

        await aliceChatSDK.endChatSession();

        final endChatSessionTime = DateTime.now().toUtc();

        final bobPresenceFromSecond =
            ChatTestHarness.awaitEvent<ChatPresenceEvent>(
              bobChatSDK,
              where: (e) => e.timestamp.isAfter(endChatSessionTime),
              timeout: const Duration(seconds: 10),
            );

        await Future<void>.delayed(const Duration(seconds: 1));

        await aliceChatSDK.startChatSession();

        final received = await bobPresenceFromSecond;
        expect(received.timestamp.isAfter(endChatSessionTime), isTrue);
      },
    );
  });
}
