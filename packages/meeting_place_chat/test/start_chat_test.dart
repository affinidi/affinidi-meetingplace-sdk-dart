import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/storage/in_memory_storage.dart';
import 'utils/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;
  late MeetingPlaceCoreSDK charlieSDK;

  late DidDocument aliceDidDocument;
  late DidDocument bobDidDocument;
  late DidDocument charlieDidDocument;

  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  late ChannelRepository aliceChannelRepository;
  late ChannelRepository bobChannelRepository;
  late ChannelRepository charlieChannelRepository;

  setUp(() async {
    aliceChannelRepository = initChannelRepository();
    bobChannelRepository = initChannelRepository();
    charlieChannelRepository = initChannelRepository();

    aliceSDK =
        await initCoreSDKInstance(channelRepository: aliceChannelRepository);

    bobSDK = await initCoreSDKInstance(channelRepository: bobChannelRepository);

    charlieSDK = await initCoreSDKInstance(
      channelRepository: charlieChannelRepository,
    );

    final aliceDidManager = await aliceSDK.generateDid();
    aliceDidDocument = await aliceDidManager.getDidDocument();

    final bobDidManager = await bobSDK.generateDid();
    bobDidDocument = await bobDidManager.getDidDocument();

    final charlieDidManager = await charlieSDK.generateDid();
    charlieDidDocument = await charlieDidManager.getDidDocument();

    await Future.wait([
      aliceSDK.mediator.updateAcl(
        ownerDidManager: aliceDidManager,
        acl: AccessListAdd(
          ownerDid: aliceDidDocument.id,
          granteeDids: [bobDidDocument.id, charlieDidDocument.id],
        ),
      ),
      bobSDK.mediator.updateAcl(
        ownerDidManager: bobDidManager,
        acl: AccessListAdd(
          ownerDid: bobDidDocument.id,
          granteeDids: [aliceDidDocument.id],
        ),
      ),
      charlieSDK.mediator.updateAcl(
        ownerDidManager: charlieDidManager,
        acl: AccessListAdd(
          ownerDid: charlieDidDocument.id,
          granteeDids: [aliceDidDocument.id],
        ),
      ),
    ]);

    final aliceVCard = VCard(values: VCardFixture.alicePrimaryVCard.values);
    final bobVCard = VCard(values: VCardFixture.bobPrimaryVCard.values);
    final charlieVCard = VCard(values: VCardFixture.charliePrimaryVCard.values);

    aliceChatSDK = await initIndividualChatSDK(
      coreSDK: aliceSDK,
      did: aliceDidDocument.id,
      otherPartyDid: bobDidDocument.id,
      channelRepository: aliceChannelRepository,
      channelVCard: aliceVCard,
      vCard: aliceVCard,
      otherPartyVCard: bobVCard,
    );

    bobChatSDK = await initIndividualChatSDK(
      coreSDK: bobSDK,
      did: bobDidDocument.id,
      otherPartyDid: aliceDidDocument.id,
      vCard: bobVCard,
      otherPartyVCard: aliceVCard,
      channelRepository: bobChannelRepository,
      channelVCard: aliceVCard,
    );

    await charlieChannelRepository.createChannel(
      Channel(
        offerLink: 'charlie',
        publishOfferDid: '',
        mediatorDid: '',
        permanentChannelDid: charlieDidDocument.id,
        otherPartyPermanentChannelDid: aliceDidDocument.id,
        status: ChannelStatus.inaugaurated,
        type: ChannelType.individual,
        vCard: charlieVCard,
        otherPartyVCard: aliceVCard,
      ),
    );
  });

  test('alice sends multiple messages', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final aliceCompleter = Completer<void>();
    final bobCompleter = Completer<void>();

    var numberOfMessagesReceived = 0;

    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          numberOfMessagesReceived++;
          if (numberOfMessagesReceived == 2) {
            bobCompleter.complete();
          }
        }
      });
    });

    final messageIds = <String>[];
    messageIds.add((await aliceChatSDK.sendTextMessage('Message#1')).messageId);
    messageIds.add((await aliceChatSDK.sendTextMessage('Message#2')).messageId);

    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatDelivered.value) {
          messageIds.remove(message.plainTextMessage?.body!['messages'][0]);
          if (messageIds.isEmpty) {
            aliceCompleter.complete();
          }
        }
      });
    });

    await bobCompleter.future;
    await aliceCompleter.future;
    expect(numberOfMessagesReceived, equals(2));

    final aliceRepositoryMessages = await aliceChatSDK.messages;
    expect(aliceRepositoryMessages.length, equals(2));

    expect(aliceRepositoryMessages[0].status, ChatItemStatus.delivered);
    expect(aliceRepositoryMessages[1].status, ChatItemStatus.delivered);

    final bobRepositoryMessages = await bobChatSDK.messages;
    expect(bobRepositoryMessages.length, equals(2));

    expect(bobRepositoryMessages[0].status, ChatItemStatus.received);
    expect(bobRepositoryMessages[1].status, ChatItemStatus.received);
  });

  test('start chatting', () async {
    final bobChatCompleted = Completer<void>();
    await bobChatSDK.startChatSession();

    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          bobChatCompleted.complete();
        }
      });
    });

    final aliceCompleted = Completer<void>();
    await aliceChatSDK.startChatSession();

    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatDelivered.value) {
          // ignore: avoid_print
          print('Chat message has been delivered successfully!');
          aliceCompleted.complete();
        }
      });
    });

    final sentMessage = await aliceChatSDK.sendTextMessage('Hello World!');
    await aliceCompleted.future;

    final actualMessages = await aliceChatSDK.messages;

    expect(
      actualMessages
          .firstWhereOrNull((m) => m.messageId == sentMessage.messageId)
          ?.status,
      equals(ChatItemStatus.delivered),
    );

    aliceChatSDK.endChatSession();

    // On resume alice will receive her chat history
    await aliceChatSDK.startChatSession();
    expect((await aliceChatSDK.messages).length, equals(1));
    aliceChatSDK.endChatSession();

    // If alice creates chat instance for different chat, chat history is
    // returned accordingly
    final aliceChatWithCharlie = await initIndividualChatSDK(
      coreSDK: aliceSDK,
      did: aliceDidDocument.id,
      otherPartyDid: charlieDidDocument.id,
      otherPartyVCard: VCardFixture.charliePrimaryVCard,
      channelRepository: aliceChannelRepository,
    );

    await aliceChatWithCharlie.startChatSession();
    expect((await aliceChatWithCharlie.messages).length, isZero);

    await bobChatCompleted.future;

    // Bob updated history as well
    final messages = await bobChatSDK.messages;
    expect(messages.length, equals(1));
  });

  test('returns new messages from mediator', () async {
    final bobChat = await bobChatSDK.startChatSession();
    expect(bobChat.messages.length, equals(0));
    bobChatSDK.endChatSession();

    await aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobChatSDK.startChatSession();

    final completer = Completer<PlainTextMessage>();
    await bobChatSDK.chatStreamSubscription.then(
      (stream) => {
        stream!.listen((data) {
          if (data.plainTextMessage?.type.toString() ==
              ChatProtocol.chatMessage.value) {
            completer.complete(data.plainTextMessage);
          }
        }),
      },
    );

    final actual = await completer.future;
    expect(actual.body!['text'], equals('Hello Bob!'));
  });

  test(
    'keeps message history if new chat SDK instance is initialized',
    () async {
      final storage = InMemoryStorage();
      final chatSDK = await initIndividualChatSDK(
        coreSDK: aliceSDK,
        did: aliceDidDocument.id,
        otherPartyDid: bobDidDocument.id,
        otherPartyVCard: VCardFixture.bobPrimaryVCard,
        existingStorage: storage,
        channelRepository: aliceChannelRepository,
      );

      await chatSDK.sendTextMessage('Hello World!');
      expect((await chatSDK.messages).length, equals(1));
      chatSDK.endChatSession();

      final chatSDKNewInstance = await initIndividualChatSDK(
        coreSDK: aliceSDK,
        did: aliceDidDocument.id,
        otherPartyDid: bobDidDocument.id,
        existingStorage: storage,
        channelRepository: aliceChannelRepository,
      );

      expect((await chatSDKNewInstance.messages).length, equals(1));
    },
  );

  // test('keeps message history if chat SDK resumes', () async {
  //   final storage = InMemoryStorage();
  //   final chatSDK = await SDKFixture.initIndividualChatSDK(
  //     coreSDK: aliceSDK,
  //     did: aliceDidDocument.id,
  //     otherPartyDid: bobDidDocument.id,
  //     existingStorage: storage,
  //     channelRepository: aliceChannelRepository,
  //   );

  //   await chatSDK.startChatSession();
  //   await chatSDK.sendTextMessage('Hello World!');
  //   expect((await chatSDK.messages).length, equals(1));
  //   chatSDK.endChatSession();

  //   await chatSDK.startChatSession();
  //   expect((await chatSDK.messages).length, equals(1));
  // });

  test('sending reactions to other party', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    // Prepare message that is going to receive reactions
    final bobChatCompleted = Completer<void>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          if (!bobChatCompleted.isCompleted) bobChatCompleted.complete();
        }
      });
    });

    await aliceChatSDK.sendTextMessage('Hello Bob!');
    await bobChatCompleted.future;

    // Consume reactions
    final messageReceivedTwoReactions = Completer<void>();
    final oneReactionRemovedFromMessage = Completer<void>();
    final message = (await bobChatSDK.messages).first as Message;

    var count = 0;
    await aliceChatSDK.chatStreamSubscription.then(
      (stream) => {
        stream!.listen((message) {
          if (MessageUtils.isType(
            message.plainTextMessage!,
            ChatProtocol.chatReaction,
          )) {
            count++;
            if (count == 2) messageReceivedTwoReactions.complete();
            if (count == 3) oneReactionRemovedFromMessage.complete();
          }
        }),
      },
    );

    // Send reactions
    await bobChatSDK.reactOnMessage(message, reaction: '👋');
    await bobChatSDK.reactOnMessage(message, reaction: '👍');
    await messageReceivedTwoReactions.future;

    // Assertion that message has two reactions
    final targetMessage =
        await aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(targetMessage.reactions, equals(['👋', '👍']));

    // One reaction is removed from message
    await bobChatSDK.reactOnMessage(message, reaction: '👋');
    await oneReactionRemovedFromMessage.future;

    // Assertion that one reaction has been removed
    final updatedMessage =
        await aliceChatSDK.getMessageById(message.messageId) as Message;
    expect(updatedMessage.reactions, equals(['👍']));
  });

  test(
    'alice receives profile hash message from Bob when Bob starts chat',
    () async {
      await aliceChatSDK.startChatSession();

      final waitForProfileHashMessage = Completer<bool>();
      await aliceChatSDK.chatStreamSubscription.then((stream) {
        stream!.listen((message) {
          if (message.plainTextMessage?.type.toString() ==
              ChatProtocol.chatAliasProfileHash.value) {
            if (!waitForProfileHashMessage.isCompleted) {
              waitForProfileHashMessage.complete(true);
            }
          }
        });
      });

      await bobChatSDK.startChatSession();
      final receivedProfileHashMessage = await waitForProfileHashMessage.future;
      expect(receivedProfileHashMessage, isTrue);
    },
  );

  test('Alice does not send profile request if profile hash matches', () async {
    await aliceChatSDK.startChatSession();
    final aliceCompleter = Completer<void>();

    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatAliasProfileHash.value) {
          if (!aliceCompleter.isCompleted) aliceCompleter.complete();
        }
      });
    });

    await bobChatSDK.startChatSession();
    var receivedProfileRequestMessage = false;

    await bobChatSDK.chatStreamSubscription.then((stream) {
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

  // test('Bob receives profile hash request if profile hashes differ', () async {
  //   await aliceChatSDK.startChatSession();
  //   final aliceProfileRequestCompleter = Completer<void>();

  //   final newBobChatSDK = await SDKFixture.initIndividualChatSDK(
  //     coreSDK: bobSDK,
  //     did: bobDidDocument.id,
  //     otherPartyDid: aliceDidDocument.id,
  //     vCard: VCard(values: {'some-values': 'changed'}),
  //     channelRepository: bobChannelRepository,
  //     channelVCard: VCardFixture.bobPrimaryVCard,
  //   );
  //   await newBobChatSDK.startChatSession();
  //   var receivedMessage = false;

  //   await newBobChatSDK.chatStreamSubscription.then((stream) {
  //     stream!.listen((message) {
  //       if (message.plainTextMessage?.type.toString() ==
  //           ChatProtocol.chatAliasProfileRequest.value) {
  //         receivedMessage = true;
  //         aliceProfileRequestCompleter.complete();
  //       }
  //     });
  //   });

  //   // Profile hash process must be invoked by sending profile hash message
  //   // because of race conditions when relying on profile hash message on
  //   // `chat.start`.
  //   await newBobChatSDK.sendProfileHash();
  //   await aliceProfileRequestCompleter.future;
  //   expect(receivedMessage, isTrue);
  // });

  test(
    'Bob has concierge message after receiving profile hash requets',
    () async {
      await aliceChatSDK.startChatSession();
      final updatedVCard = VCard(values: {'changed': 'value'});

      final aliceOpenedChat = Completer<void>();
      await aliceChatSDK.chatStreamSubscription.then((stream) {
        aliceOpenedChat.complete();
      });

      await aliceOpenedChat.future;

      final newBobChatSDK = await initIndividualChatSDK(
        coreSDK: bobSDK,
        did: bobDidDocument.id,
        otherPartyDid: aliceDidDocument.id,
        vCard: updatedVCard,
        channelRepository: bobChannelRepository,
        channelVCard: VCardFixture.bobPrimaryVCard,
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

      // Profile hash process must be invoked by sending profile hash message
      // because of race conditions when relying on profile hash message on
      // `chat.start`.
      await newBobChatSDK.sendProfileHash();
      await bobProfileRequestCompleter.future;

      final conciergeMessage = (await newBobChatSDK.messages).firstWhere(
        (chatItem) => chatItem.type == ChatItemType.conciergeMessage,
      ) as ConciergeMessage;

      expect(conciergeMessage.isFromMe, false);
      expect(conciergeMessage.chatId, bobChat.id);
      expect(conciergeMessage.status, ChatItemStatus.userInput);
      expect(conciergeMessage.data, {
        'profileHash': updatedVCard.toHash(),
        'replyTo': aliceDidDocument.id,
      });

      final aliceChatCompleter = Completer<void>();

      await aliceChatSDK.chatStreamSubscription.then((stream) {
        stream!.listen((message) async {
          if (message.plainTextMessage?.type.toString() ==
              ChatProtocol.chatContactDetailsUpdate.value) {
            aliceChatCompleter.complete();
          }
        });
      });

      // Bob approves updating contact details
      await newBobChatSDK.sendChatContactDetailsUpdate(conciergeMessage);

      // Alice received contact details update
      await aliceChatCompleter.future;
      final aliceChannel = await aliceSDK.getChannelByDid(bobDidDocument.id);
      expect(
        aliceChannel?.otherPartyVCard?.values,
        equals(updatedVCard.values),
      );
    },
  );

  test('reject contact profile update', () async {
    await aliceChatSDK.startChatSession();
    final updatedVCard = VCard(values: {'changed': 'value'});

    final aliceOpenedChat = Completer<void>();
    await aliceChatSDK.chatStreamSubscription.then((stream) {
      aliceOpenedChat.complete();
    });

    await aliceOpenedChat.future;

    final newBobChatSDK = await initIndividualChatSDK(
      coreSDK: bobSDK,
      did: bobDidDocument.id,
      otherPartyDid: aliceDidDocument.id,
      vCard: updatedVCard,
      channelRepository: bobChannelRepository,
      channelVCard: VCardFixture.bobPrimaryVCard,
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

    // Profile hash process must be invoked by sending profile hash message
    // because of race conditions when relying on profile hash message on
    // `chat.start`.
    await newBobChatSDK.sendProfileHash();
    await bobProfileRequestCompleter.future;

    final conciergeMessage = (await newBobChatSDK.messages).firstWhere(
      (chatItem) => chatItem.type == ChatItemType.conciergeMessage,
    ) as ConciergeMessage;

    final aliceChatCompleter = Completer<void>();

    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) async {
        if (message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatContactDetailsUpdate.value) {
          aliceChatCompleter.complete();
        }
      });
    });

    // Bob approves updating contact details
    await newBobChatSDK.rejectChatContactDetailsUpdate(conciergeMessage);
    expect(conciergeMessage.status, equals(ChatItemStatus.confirmed));
  });

  test('chat message attachments', () async {
    await bobChatSDK.startChatSession();

    final attachments = [
      Attachment(
        id: const Uuid().v4(),
        description: 'Sample attachment',
        filename: 'attachment.jpeg',
        mediaType: AttachmentMediaType.imageJpeg.value,
        format: AttachmentFormat.imageSelfie.value,
        lastModifiedTime: DateTime.now().toUtc(),
        data: AttachmentData(
          base64:
              'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==',
        ),
        byteCount: 160,
      ),
    ];

    await aliceChatSDK.startChatSession();
    final message = await aliceChatSDK.sendTextMessage(
      'Hello World!',
      attachments: attachments,
    );

    final bobWaitForAttachments = Completer<List<Attachment>>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
                ChatProtocol.chatMessage.value &&
            message.messageId == data.plainTextMessage?.id) {
          bobWaitForAttachments
              .complete(data.plainTextMessage?.attachments ?? []);
        }
      });
    });

    final receivedAttachments = await bobWaitForAttachments.future;

    // Received message has attachments
    expect(receivedAttachments.first.toJson(), attachments.first.toJson());

    // Bob's repository contains attachment
    final bobMessages = await bobChatSDK.messages;
    expect(
      (bobMessages.first as Message).attachments.first.toJson(),
      attachments.first.toJson(),
    );

    // Alice's repository contains attachment
    final aliceMessages = await aliceChatSDK.messages;
    expect(
      (aliceMessages[0] as Message).attachments[0].toJson(),
      attachments[0].toJson(),
    );
  });

  test('sends chat presence message in configured interval', () async {
    final chatSDKWithReducedInterval = await initIndividualChatSDK(
      coreSDK: aliceSDK,
      did: aliceDidDocument.id,
      otherPartyDid: bobDidDocument.id,
      channelRepository: aliceChannelRepository,
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
