import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('sendMessage sets from/to and sends message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          if (!bobCompleter.isCompleted) {
            bobCompleter.complete(data.plainTextMessage!);
          }
        }
      });
    });

    final message = CustomMessage(
      id: 'test-id',
      type: ChatProtocol.chatMessage.value,
      body: {
        'text': 'Hello via sendMessage',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendMessage(message);

    final received = await bobCompleter.future;
    expect(received.body!['text'], equals('Hello via sendMessage'));
    expect(received.from, equals(fixture.aliceSDK.didDocument.id));
    expect(received.to?.first, equals(fixture.bobSDK.didDocument.id));
  });

  test('sendMessage with notify flag sends notification', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          if (!bobCompleter.isCompleted) {
            bobCompleter.complete(data.plainTextMessage!);
          }
        }
      });
    });

    final message = CustomMessage(
      id: 'notify-id',
      type: ChatProtocol.chatMessage.value,
      body: {
        'text': 'Notify test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendMessage(message, notify: true);

    final received = await bobCompleter.future;
    expect(received.body!['text'], equals('Notify test'));
    expect(received.from, equals(fixture.aliceSDK.didDocument.id));
    expect(received.to?.first, equals(fixture.bobSDK.didDocument.id));
    expect(received.id, equals('notify-id'));

    final bobMessages = await fixture.bobChatSDK.messages;
    expect(
      bobMessages.whereType<Message>().any((m) => m.messageId == 'notify-id'),
      isTrue,
      reason:
          'Message with notify flag should be persisted in Bob\'s repository',
    );
  });
}
