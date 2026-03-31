import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../utils/group_chat_fixture.dart';

void main() {
  final messageType = Uri.parse('https://affinidi.io/mpx/core-sdk/test');

  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
  });

  test('group member sends group message', () async {
    final chatMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: messageType,
      from: fixture.bobDid,
      to: [fixture.groupDid],
      body: {'text': 'Hello Group!', 'seq_no': 2},
      attachments: [],
    );

    final aliceStream = await fixture.aliceSDK.subscribeToMediator(
      fixture.aliceDid,
    );
    final aliceReceivedMessageCompleter = Completer<PlainTextMessage>();

    final charlieStream = await fixture.charlieSDK.subscribeToMediator(
      fixture.charlieDid,
    );
    final charlieReceivedMessageCompleter = Completer<PlainTextMessage>();

    aliceStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 2) {
        aliceReceivedMessageCompleter.complete(data.plainTextMessage);
        aliceStream.dispose();
      }
    });

    charlieStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 2) {
        charlieReceivedMessageCompleter.complete(data.plainTextMessage);
        charlieStream.dispose();
      }
    });

    await fixture.bobSDK.sendGroupMessage(
      chatMessage,
      senderDid: fixture.bobDid,
      recipientDid: fixture.groupDid,
      increaseSequenceNumber: true,
    );

    final aliceReceivedMessage = await aliceReceivedMessageCompleter.future;
    expect(aliceReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(aliceReceivedMessage.body!['seq_no'], equals(2));

    final charlieReceivedMessage = await charlieReceivedMessageCompleter.future;
    expect(charlieReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(charlieReceivedMessage.body!['seq_no'], equals(2));
  });

  test('group admin sends group message', () async {
    final messageId = const Uuid().v4();
    final chatMessage = PlainTextMessage(
      id: messageId,
      type: messageType,
      from: fixture.aliceDid,
      to: [fixture.groupDid],
      body: {'text': 'Hello Group!', 'seq_no': 1},
    );

    final bobStream = await fixture.bobSDK.subscribeToMediator(fixture.bobDid);
    final charlieStream = await fixture.charlieSDK.subscribeToMediator(
      fixture.charlieDid,
    );

    final bobReceivedMessageCompleter = Completer<PlainTextMessage>();
    final charlieReceivedMessageCompleter = Completer<PlainTextMessage>();

    bobStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 1) {
        bobReceivedMessageCompleter.complete(data.plainTextMessage);
        bobStream.dispose();
      }
    });

    charlieStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 1) {
        charlieReceivedMessageCompleter.complete(data.plainTextMessage);
        charlieStream.dispose();
      }
    });

    await Future<void>.delayed(const Duration(seconds: 3));

    await fixture.aliceSDK.sendGroupMessage(
      chatMessage,
      senderDid: fixture.aliceDid,
      recipientDid: fixture.groupDid,
      increaseSequenceNumber: true,
    );

    final bobReceivedMessage = await bobReceivedMessageCompleter.future;
    expect(bobReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(bobReceivedMessage.body!['seq_no'], equals(1));

    final charlieReceivedMessage = await charlieReceivedMessageCompleter.future;
    expect(charlieReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(charlieReceivedMessage.body!['seq_no'], equals(1));
  });
}
