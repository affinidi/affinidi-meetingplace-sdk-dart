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

  test('group owner sends message to members', () async {
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final bobChatCompleter = Completer<Message>();
    final charlieChatCompleter = Completer<Message>();

    final streams = await Future.wait([
      fixture.bobChatSDK.chatStreamSubscription,
      fixture.charlieChatSDK.chatStreamSubscription,
    ]);

    final bobStream = streams[0]!;
    final charlieStream = streams[1]!;

    bobStream.listen((data) {
      if (data.event is ChatMessageEvent &&
          (data.chatItem as Message?)?.value == 'Hello Group!' &&
          !bobChatCompleter.isCompleted) {
        bobChatCompleter.complete(data.chatItem as Message);
      }
    });

    charlieStream.listen((data) {
      if (data.event is ChatMessageEvent &&
          (data.chatItem as Message?)?.value == 'Hello Group!' &&
          !charlieChatCompleter.isCompleted) {
        charlieChatCompleter.complete(data.chatItem as Message);
      }
    });

    await fixture.aliceChatSDK.sendTextMessage('Hello Group!');

    final messageForBob = await bobChatCompleter.future;
    final messageForCharlie = await charlieChatCompleter.future;

    expect(messageForBob.value, equals('Hello Group!'));
    expect(messageForCharlie.value, equals('Hello Group!'));
  });

  test('send activity message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final messageReceivedCompleter = Completer<bool>();
    await fixture.charlieChatSDK.chatStreamSubscription.then((stream) async {
      stream!.listen((data) {
        if (data.event is ChatActivityEvent) {
          if (!messageReceivedCompleter.isCompleted) {
            messageReceivedCompleter.complete(true);
            stream.dispose();
          }
        }
      });

      await fixture.bobChatSDK.sendChatActivity();
    });

    final messageReceived = await messageReceivedCompleter.future;
    expect(messageReceived, isTrue);
  });
}
