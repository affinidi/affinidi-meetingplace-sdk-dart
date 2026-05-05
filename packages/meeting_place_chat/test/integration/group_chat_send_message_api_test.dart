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

    final bobCompleter = Completer<Message>();
    final bobChatStream = await fixture.bobChatSDK.chatStreamSubscription;
    bobChatStream!.listen((data) {
      if (data.event is ChatMessageEvent &&
          data.chatItem != null &&
          !bobCompleter.isCompleted) {
        bobCompleter.complete(data.chatItem as Message);
        bobChatStream.dispose();
      }
    });

    final charlieCompleter = Completer<Message>();
    final charlieChatStream =
        await fixture.charlieChatSDK.chatStreamSubscription;
    charlieChatStream!.listen((data) {
      if (data.event is ChatMessageEvent &&
          data.chatItem != null &&
          !charlieCompleter.isCompleted) {
        charlieCompleter.complete(data.chatItem as Message);
        charlieChatStream.dispose();
      }
    });

    final message = CustomMessage(
      id: 'group-test-id',
      type: ChatProtocol.chatMessage.value,
      body: {
        'text': 'Hello group via sendMessage',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendMessage(message);

    final receivedByBob = await bobCompleter.future;
    final receivedByCharlie = await charlieCompleter.future;

    expect(receivedByBob.value, equals('Hello group via sendMessage'));
    expect(receivedByBob.senderDid, equals(fixture.groupOwnerDidDocument.id));

    expect(receivedByCharlie.value, equals('Hello group via sendMessage'));
    expect(
      receivedByCharlie.senderDid,
      equals(fixture.groupOwnerDidDocument.id),
    );
  });

  test('group sendMessage with notify flag delivers message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobCompleter = Completer<Message>();

    final chatStream = await fixture.bobChatSDK.chatStreamSubscription;
    chatStream!.listen((data) {
      if (data.event is ChatMessageEvent &&
          (data.chatItem as Message?)?.value == 'Notify group test' &&
          !bobCompleter.isCompleted) {
        bobCompleter.complete(data.chatItem as Message);
        chatStream.dispose();
      }
    });

    final message = CustomMessage(
      id: 'group-notify-id',
      type: ChatProtocol.chatMessage.value,
      body: {
        'text': 'Notify group test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await fixture.aliceChatSDK.sendMessage(message, notify: true);

    final received = await bobCompleter.future;
    expect(received.value, equals('Notify group test'));
    expect(received.senderDid, equals(fixture.groupOwnerDidDocument.id));
    expect(received.messageId, equals('group-notify-id'));
  });
}
