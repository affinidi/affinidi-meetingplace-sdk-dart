import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import 'utils/group_chat_fixture.dart';

void main() {
  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
  });

  tearDown(() {
    fixture.disposeSessions();
  });

  test('group member sendMessage sets from/to and delivers to group', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();
    final bobChatStream = await fixture.bobChatSDK.chatStreamSubscription;
    bobChatStream!.listen((data) {
      if (data.plainTextMessage?.type.toString() ==
          ChatProtocol.chatMessage.value) {
        if (!bobCompleter.isCompleted) {
          bobCompleter.complete(data.plainTextMessage!);
          bobChatStream.dispose();
        }
      }
    });

    final charlieCompleter = Completer<PlainTextMessage>();
    final charlieChatStream =
        await fixture.charlieChatSDK.chatStreamSubscription;
    charlieChatStream!.listen((data) {
      if (data.plainTextMessage?.type.toString() ==
          ChatProtocol.chatMessage.value) {
        if (!charlieCompleter.isCompleted) {
          charlieCompleter.complete(data.plainTextMessage!);
          charlieChatStream.dispose();
        }
      }
    });

    final message = PlainTextMessage(
      id: 'group-test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: fixture.groupOwnerDidDocument.id,
      to: [fixture.publishOfferResult.connectionOffer.groupDid!],
      body: {
        'text': 'Hello group via sendMessage',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendMessage(message);

    final receivedByBob = await bobCompleter.future;
    final receivedByCharlie = await charlieCompleter.future;

    expect(receivedByBob.body!['text'], equals('Hello group via sendMessage'));
    expect(receivedByBob.from, equals(fixture.groupOwnerDidDocument.id));
    expect(
      receivedByBob.to?.first,
      equals(fixture.publishOfferResult.connectionOffer.groupDid!),
    );

    expect(
      receivedByCharlie.body!['text'],
      equals('Hello group via sendMessage'),
    );
    expect(receivedByCharlie.from, equals(fixture.groupOwnerDidDocument.id));
    expect(
      receivedByCharlie.to?.first,
      equals(fixture.publishOfferResult.connectionOffer.groupDid!),
    );
  });

  test('group sendMessage throws if from/to are set incorrectly', () async {
    await fixture.aliceChatSDK.startChatSession();

    final wrongFrom = PlainTextMessage(
      id: 'group-test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: 'did:wrong:alice',
      body: {'text': 'Should fail'},
    );

    expect(
      () => fixture.aliceChatSDK.sendMessage(wrongFrom),
      throwsA(isA<Exception>()),
    );

    final wrongTo = PlainTextMessage(
      id: 'group-test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      to: ['did:wrong:group'],
      body: {'text': 'Should fail'},
    );

    expect(
      () => fixture.aliceChatSDK.sendMessage(wrongTo),
      throwsA(isA<Exception>()),
    );
  });

  test('group sendMessage with notify flag delivers message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();

    final chatStream = await fixture.bobChatSDK.chatStreamSubscription;
    chatStream!.listen((data) {
      if (data.plainTextMessage?.type.toString() ==
          ChatProtocol.chatMessage.value) {
        if (data.plainTextMessage?.body?['text'] == 'Notify group test' &&
            !bobCompleter.isCompleted) {
          bobCompleter.complete(data.plainTextMessage!);
          chatStream.dispose();
        }
      }
    });

    final message = PlainTextMessage(
      id: 'group-notify-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: fixture.groupOwnerDidDocument.id,
      to: [fixture.publishOfferResult.connectionOffer.groupDid!],
      body: {
        'text': 'Notify group test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendMessage(message, notify: true);

    final received = await bobCompleter.future;
    expect(received.body!['text'], equals('Notify group test'));
    expect(received.from, equals(fixture.groupOwnerDidDocument.id));
    expect(
      received.to?.first,
      equals(fixture.publishOfferResult.connectionOffer.groupDid!),
    );
    expect(received.id, equals('group-notify-id'));
  });
}
