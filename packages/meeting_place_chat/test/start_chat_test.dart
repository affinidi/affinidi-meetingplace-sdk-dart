import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/contact_card_fixture.dart' as fixtures;
import 'utils/setup_chat_sdk.dart';
import 'utils/storage/in_memory_storage.dart';

void main() async {
  final setup = SetupChatSdk();

  late SDKInstance aliceSDK;
  late SDKInstance bobSDK;
  late SDKInstance charlieSDK;

  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  setUp(() async {
    aliceSDK = await setup.createCoreSDK(
      fixtures.ContactCardFixture.alicePrimaryCardInfo,
    );

    bobSDK = await setup.createCoreSDK(
      fixtures.ContactCardFixture.bobPrimaryCardInfo,
    );

    charlieSDK = await setup.createCoreSDK(
      fixtures.ContactCardFixture.charliePrimaryCardInfo,
    );

    aliceChatSDK = await setup.createChatSdk(
      sdkInstance: aliceSDK,
      otherPartySdkInstance: bobSDK,
    );

    bobChatSDK = await setup.createChatSdk(
      sdkInstance: bobSDK,
      otherPartySdkInstance: aliceSDK,
    );

    await charlieSDK.channelRepository.createChannel(
      Channel(
        offerLink: 'charlie',
        publishOfferDid: '',
        mediatorDid: '',
        permanentChannelDid: charlieSDK.didDocument.id,
        otherPartyPermanentChannelDid: aliceSDK.didDocument.id,
        status: ChannelStatus.inaugurated,
        type: ChannelType.individual,
        isConnectionInitiator: false,
        contactCard: charlieSDK.contactCard,
        otherPartyContactCard: aliceSDK.contactCard,
      ),
    );
  });

  tearDown(() {
    aliceChatSDK.endChatSession();
    bobChatSDK.endChatSession();
  });

  test('alice sends multiple messages', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final aliceCompleter = Completer<void>();
    final bobCompleter = Completer<void>();

    final receivedMessageIds = <String>[];
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        final isChatMessage =
            message.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value;

        if (isChatMessage &&
            !receivedMessageIds.contains(message.plainTextMessage!.id)) {
          receivedMessageIds.add(message.plainTextMessage!.id);
          if (receivedMessageIds.length == 2) {
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
          final removed = messageIds.remove(
            message.plainTextMessage?.body!['messages'][0],
          );
          if (messageIds.isEmpty && removed) {
            aliceCompleter.complete();
          }
        }
      });
    });

    await bobCompleter.future;
    await aliceCompleter.future;
    expect(receivedMessageIds.length, equals(2));

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
        if (!bobChatCompleted.isCompleted &&
            data.plainTextMessage?.type.toString() ==
                ChatProtocol.chatMessage.value) {
          bobChatCompleted.complete();
        }
      });
    });

    final aliceCompleted = Completer<void>();
    await aliceChatSDK.startChatSession();

    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) {
        if (!aliceCompleted.isCompleted &&
            message.plainTextMessage?.type.toString() ==
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
    final aliceChatWithCharlie = await setup.createChatSdk(
      sdkInstance: aliceSDK,
      otherPartySdkInstance: charlieSDK,
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
          final isChatMessage =
              data.plainTextMessage?.type.toString() ==
              ChatProtocol.chatMessage.value;

          if (isChatMessage && !completer.isCompleted) {
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
      // Explicitly using in-memory storage to ensure that same storage instance
      // is used for both chat SDK instances in this test
      final storage = InMemoryStorage();

      // First chat SDK instance to send message and end chat session
      final chatSDK = await setup.createChatSdk(
        sdkInstance: aliceSDK,
        otherPartySdkInstance: bobSDK,
        storage: storage,
      );

      await chatSDK.sendTextMessage('Hello World!');
      expect((await chatSDK.messages).length, equals(1));
      chatSDK.endChatSession();

      // New chat SDK instance is initialized and is expected to have the same
      // message history
      final chatSDKNewInstance = await setup.createChatSdk(
        sdkInstance: aliceSDK,
        otherPartySdkInstance: bobSDK,
        storage: storage,
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

      // Update channel to trigger profile hash message
      final channel = await bobSDK.coreSDK.getChannelByDid(
        bobSDK.didDocument.id,
      );
      final contactCard = channel!.contactCard!;
      contactCard.contactInfo['changed'] = 'value';
      await bobSDK.coreSDK.updateChannel(channel);

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

    final channel = await bobSDK.coreSDK.getChannelByDid(bobSDK.didDocument.id);
    final contactCard = channel!.contactCard!;
    contactCard.contactInfo['changed'] = 'value';
    await bobSDK.coreSDK.updateChannel(channel);

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
  //     channelRepository: bobChannelRepository,
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
      final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
        did: bobSDK.didDocument.id,
        contactInfo: {'changed': 'value'},
      );

      final aliceOpenedChat = Completer<void>();
      await aliceChatSDK.chatStreamSubscription.then((stream) {
        aliceOpenedChat.complete();
      });

      await aliceOpenedChat.future;

      final newBobChatSDK = await setup.createChatSdk(
        sdkInstance: bobSDK,
        otherPartySdkInstance: aliceSDK,
        card: updatedCard,
        channelCard: fixtures.ContactCardFixture.getContactCardFixture(
          did: bobSDK.didDocument.id,
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

      // Profile hash process must be invoked by sending profile hash message
      // because of race conditions when relying on profile hash message on
      // `chat.start`.
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
        'replyTo': aliceSDK.didDocument.id,
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
      final aliceChannel = await aliceSDK.coreSDK.getChannelByDid(
        bobSDK.didDocument.id,
      );
      expect(
        aliceChannel?.otherPartyContactCard?.contactInfo,
        equals(updatedCard.contactInfo),
      );
    },
  );

  test('reject contact profile update', () async {
    await aliceChatSDK.startChatSession();
    final updatedCard = fixtures.ContactCardFixture.getContactCardFixture(
      did: bobSDK.didDocument.id,
      contactInfo: {'changed': 'value'},
    );

    final aliceOpenedChat = Completer<void>();
    await aliceChatSDK.chatStreamSubscription.then((stream) {
      aliceOpenedChat.complete();
    });

    await aliceOpenedChat.future;

    final newBobChatSDK = await setup.createChatSdk(
      sdkInstance: bobSDK,
      otherPartySdkInstance: aliceSDK,
      card: updatedCard,
      channelCard: fixtures.ContactCardFixture.getContactCardFixture(
        did: bobSDK.didDocument.id,
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

    // Profile hash process must be invoked by sending profile hash message
    // because of race conditions when relying on profile hash message on
    // `chat.start`.
    await newBobChatSDK.sendProfileHash();
    await bobProfileRequestCompleter.future;

    final conciergeMessage =
        (await newBobChatSDK.messages).firstWhere(
              (chatItem) => chatItem.type == ChatItemType.conciergeMessage,
            )
            as ConciergeMessage;

    final aliceChatCompleter = Completer<void>();

    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) async {
        if (!aliceChatCompleter.isCompleted &&
            message.plainTextMessage?.type.toString() ==
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
        if (!bobWaitForAttachments.isCompleted &&
            data.plainTextMessage?.type.toString() ==
                ChatProtocol.chatMessage.value &&
            message.messageId == data.plainTextMessage?.id) {
          stream.dispose();
          bobWaitForAttachments.complete(
            data.plainTextMessage?.attachments ?? [],
          );
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

  test('message is shown as sent even for notification error', () async {
    final channel = await aliceSDK.coreSDK.getChannelByDid(
      aliceSDK.didDocument.id,
    );
    channel!.otherPartyNotificationToken = 'invalid_token';
    await aliceSDK.coreSDK.updateChannel(channel);

    await aliceChatSDK.startChatSession();
    final actual = await aliceChatSDK.sendTextMessage('Sample text message');
    expect(actual.status, ChatItemStatus.sent);
  });

  test('sendMessage sets from/to and sends message', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          if (!bobCompleter.isCompleted) {
            bobCompleter.complete(data.plainTextMessage!);
          }
        }
      });
    });

    final message = PlainTextMessage(
      id: 'test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: aliceSDK.didDocument.id,
      to: [bobSDK.didDocument.id],
      body: {
        'text': 'Hello via sendMessage',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await aliceChatSDK.sendMessage(message);

    final received = await bobCompleter.future;
    expect(received.body!['text'], equals('Hello via sendMessage'));
    expect(received.from, equals(aliceSDK.didDocument.id));
    expect(received.to?.first, equals(bobSDK.didDocument.id));
  });

  test('sendMessage throws if from/to are set incorrectly', () async {
    await aliceChatSDK.startChatSession();

    final wrongFrom = PlainTextMessage(
      id: 'test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: 'did:wrong:alice',
      body: {'text': 'Should fail'},
    );

    expect(
      () => aliceChatSDK.sendMessage(wrongFrom),
      throwsA(isA<Exception>()),
    );

    final wrongTo = PlainTextMessage(
      id: 'test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      to: ['did:wrong:bob'],
      body: {'text': 'Should fail'},
    );

    expect(() => aliceChatSDK.sendMessage(wrongTo), throwsA(isA<Exception>()));
  });

  test('sendMessage with notify flag sends notification', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          if (!bobCompleter.isCompleted) {
            bobCompleter.complete(data.plainTextMessage!);
          }
        }
      });
    });

    final message = PlainTextMessage(
      id: 'notify-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: aliceSDK.didDocument.id,
      to: [bobSDK.didDocument.id],
      body: {
        'text': 'Notify test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await aliceChatSDK.sendMessage(message, notify: true);

    final received = await bobCompleter.future;
    expect(received.body!['text'], equals('Notify test'));
    expect(received.from, equals(aliceSDK.didDocument.id));
    expect(received.to?.first, equals(bobSDK.didDocument.id));
    expect(received.id, equals('notify-id'));

    final bobMessages = await bobChatSDK.messages;
    expect(
      bobMessages.whereType<Message>().any((m) => m.messageId == 'notify-id'),
      isTrue,
      reason:
          'Message with notify flag should be persisted in Bob\'s repository',
    );
  });

  test('unhandled message is pushed to chat stream', () async {
    final unhandledMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://example.com/${Uuid().v4()}'),
      from: bobSDK.didDocument.id,
      to: [aliceSDK.didDocument.id],
      body: {'text': 'Hello Alice!'},
    );

    final pushedToChatStream = Completer<StreamData>();

    await aliceChatSDK.startChatSession();
    await aliceChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((message) async {
        if (message.plainTextMessage?.type == unhandledMessage.type) {
          pushedToChatStream.complete(message);
          stream.dispose();
        }
      });
    });

    await bobSDK.coreSDK.sendMessage(
      unhandledMessage,
      senderDid: bobSDK.didDocument.id,
      recipientDid: aliceSDK.didDocument.id,
    );

    final receivedStreamData = await pushedToChatStream.future.timeout(
      const Duration(seconds: 10),
    );

    expect(receivedStreamData, isA<StreamData>());

    expect(
      receivedStreamData.plainTextMessage?.id,
      equals(unhandledMessage.id),
    );
  });
}
