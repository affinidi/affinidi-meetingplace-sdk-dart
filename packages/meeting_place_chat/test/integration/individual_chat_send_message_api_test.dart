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

  test('sendRoomEvent delivers message to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobCompleter = Completer<Message>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.event is ChatMessageEvent && !bobCompleter.isCompleted) {
          bobCompleter.complete(data.chatItem as Message);
        }
      });
    });

    final event = CustomRoomEvent(
      type: ChatProtocol.chatMessage.value,
      content: {
        'text': 'Hello via sendRoomEvent',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendRoomEvent(event);

    final received = await bobCompleter.future;
    expect(received.value, equals('Hello via sendRoomEvent'));
    expect(received.senderDid, equals(fixture.aliceSDK.didDocument.id));
  });

  test('sendRoomEvent message is persisted in repository', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobCompleter = Completer<Message>();
    await fixture.bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.event is ChatMessageEvent && !bobCompleter.isCompleted) {
          bobCompleter.complete(data.chatItem as Message);
        }
      });
    });

    final event = CustomRoomEvent(
      type: ChatProtocol.chatMessage.value,
      content: {
        'text': 'Persist test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendRoomEvent(event);

    final received = await bobCompleter.future;
    expect(received.value, equals('Persist test'));
    expect(received.senderDid, equals(fixture.aliceSDK.didDocument.id));

    final bobMessages = await fixture.bobChatSDK.messages;
    expect(
      bobMessages.whereType<Message>().any(
        (m) => m.value == 'Persist test',
      ),
      isTrue,
      reason: 'Message should be persisted in Bob\'s repository',
    );
  });
}
