import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
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

    final bobChatCompleter = Completer<PlainTextMessage>();
    final charlieChatCompleter = Completer<PlainTextMessage>();

    final streams = await Future.wait([
      fixture.bobChatSDK.chatStreamSubscription,
      fixture.charlieChatSDK.chatStreamSubscription,
    ]);

    final bobStream = streams[0]!;
    final charlieStream = streams[1]!;

    void handleMessage({
      required Completer<PlainTextMessage> completer,
      required PlainTextMessage? message,
    }) {
      if (message == null ||
          !message.isOfType(ChatProtocol.chatMessage.value)) {
        return;
      }

      final chatMessage = ChatMessage.fromPlainTextMessage(message);
      if (chatMessage.body.text == 'Hello Group!' && !completer.isCompleted) {
        completer.complete(message);
      }
    }

    bobStream.listen((data) {
      handleMessage(
        completer: bobChatCompleter,
        message: data.plainTextMessage,
      );
    });

    charlieStream.listen((data) {
      handleMessage(
        completer: charlieChatCompleter,
        message: data.plainTextMessage,
      );
    });

    await fixture.aliceChatSDK.sendTextMessage('Hello Group!');

    final messageForBob = await bobChatCompleter.future;
    final messageForCharlie = await charlieChatCompleter.future;

    expect(messageForBob.body!['text'], equals('Hello Group!'));
    expect(messageForCharlie.body!['text'], equals('Hello Group!'));
  });

  test('send activity message', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();
    await fixture.charlieChatSDK.startChatSession();

    final messageReceivedCompleter = Completer<bool>();
    await fixture.charlieChatSDK.chatStreamSubscription.then((stream) async {
      stream!.listen((data) {
        if (data.plainTextMessage?.isOfType(ChatProtocol.chatActivity.value) ==
            true) {
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
