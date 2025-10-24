import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  test('listener receives messages', () async {
    // --- Create OOBs ---
    final didManagerA = await aliceSDK.generateDid();
    final didDocA = await didManagerA.getDidDocument();

    final didManagerB = await aliceSDK.generateDid();
    final didDocB = await didManagerB.getDidDocument();

    // --- Reset messages ---
    await aliceSDK.mediator.fetchMessages(
      didManager: didManagerA,
      deleteOnRetrieve: true,
    );

    await aliceSDK.mediator.fetchMessages(
      didManager: didManagerB,
      deleteOnRetrieve: true,
    );

    Map<String, dynamic>? stream1Body;
    Map<String, dynamic>? stream2Body;

    // --- Subscriptions ---
    final stream1 = await aliceSDK.mediator.subscribeToMessages(didManagerA);

    stream1.listen((message) {
      if (message.type.toString() == 'https://example.com/test') {
        stream1Body = message.body;
      }
    });

    final stream2 = await aliceSDK.mediator.subscribeToMessages(didManagerB);

    stream2.listen((message) {
      if (message.type.toString() == 'https://example.com/test') {
        stream2Body = message.body;
      }
    });

    // --- Send messages ---
    final sendMessageDid = await bobSDK.generateDid();
    final senderDidDocument = await sendMessageDid.getDidDocument();

    await bobSDK.mediator.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: senderDidDocument.id,
        to: [didDocA.id],
        body: {'fooA': 'barA'},
      ),
      senderDidManager: sendMessageDid,
      recipientDidDocument: didDocA,
      next: didDocA.id,
    );

    await bobSDK.mediator.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: senderDidDocument.id,
        to: [didDocB.id],
        body: {'fooB': 'barB'},
      ),
      senderDidManager: sendMessageDid,
      recipientDidDocument: didDocB,
      next: didDocB.id,
    );

    await Future<void>.delayed(const Duration(seconds: 5));

    final messagesA = await aliceSDK.mediator.fetchMessages(
      didManager: didManagerA,
    );

    final targetMessages = messagesA
        .where(
          (mes) => mes.message!.type.toString() == 'https://example.com/test',
        )
        .toList();

    expect(targetMessages.length, 0);

    final messagesB = await aliceSDK.mediator.fetchMessages(
      didManager: didManagerB,
    );

    final targetMessagesB = messagesB
        .where((mes) => mes.message!.toString() == 'https://example.com/test')
        .toList();

    expect(targetMessagesB.length, 0);

    expect(stream1Body, {'fooA': 'barA'});
    expect(stream2Body, {'fooB': 'barB'});

    await stream1.dispose();
    await stream2.dispose();
  }, skip: 'check');

  test('subscription cares only about related messages', () async {
    // --- Create OOBs ---
    final didManagerA = await aliceSDK.generateDid();
    final didDocA = await didManagerA.getDidDocument();

    final didManagerB = await aliceSDK.generateDid();
    final didDocB = await didManagerB.getDidDocument();

    // --- Reset messages ---
    await aliceSDK.mediator.fetchMessages(
      didManager: didManagerA,
      deleteOnRetrieve: true,
    );

    await aliceSDK.mediator.fetchMessages(
      didManager: didManagerB,
      deleteOnRetrieve: true,
    );

    // --- Send messages ---
    final sendMessageDid = await bobSDK.generateDid();
    final senderDidDocument = await sendMessageDid.getDidDocument();

    await aliceSDK.mediator.updateAcl(
      ownerDidManager: didManagerA,
      acl: AccessListAdd(
        ownerDid: didDocA.id,
        granteeDids: [senderDidDocument.id],
      ),
    );

    await aliceSDK.mediator.updateAcl(
      ownerDidManager: didManagerB,
      acl: AccessListAdd(
        ownerDid: didDocB.id,
        granteeDids: [senderDidDocument.id],
      ),
    );

    await bobSDK.mediator.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: senderDidDocument.id,
        to: [didDocA.id],
        body: {'fooA': 'barA'},
      ),
      senderDidManager: sendMessageDid,
      recipientDidDocument: didDocA,
      next: didDocA.id,
    );

    await bobSDK.mediator.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: senderDidDocument.id,
        to: [didDocB.id],
        body: {'fooB': 'barB'},
      ),
      senderDidManager: sendMessageDid,
      recipientDidDocument: didDocB,
      next: didDocB.id,
    );

    await Future<void>.delayed(const Duration(seconds: 5));

    final messagesA = await aliceSDK.mediator.fetchMessages(
      didManager: didManagerA,
    );

    final targetMessages = messagesA
        .where(
          (mes) => mes.message!.type.toString() == 'https://example.com/test',
        )
        .toList();

    expect(targetMessages.length, 1);

    final messagesB = await aliceSDK.mediator.fetchMessages(
      didManager: didManagerB,
    );

    final targetMessagesB = messagesB
        .where(
          (mes) => mes.message!.type.toString() == 'https://example.com/test',
        )
        .toList();

    expect(targetMessagesB.length, 1);
  });

  test('different stream for each mediator session', () async {
    final didManager = await aliceSDK.generateDid();
    final didManager2 = await aliceSDK.generateDid();

    final channel = await aliceSDK.mediator.subscribeToMessages(didManager);

    final differentChannel = await aliceSDK.mediator.subscribeToMessages(
      didManager2,
    );

    expect(channel, isNot(equals(differentChannel)));
    await channel.dispose();
    await differentChannel.dispose();
  });

  test('failed message processing keeps messages on mediator', () async {
    final oobDidManager = await aliceSDK.generateDid();
    final oobDidDocument = await oobDidManager.getDidDocument();
    final oobInvitationMessage = OobInvitationMessage.create(
      from: oobDidDocument.id,
    );

    // Reset messages
    await aliceSDK.mediator.fetchMessages(
      didManager: oobDidManager,
      deleteOnRetrieve: true,
    );

    Map<String, dynamic>? streamMessage;

    final channel = await aliceSDK.mediator.subscribeToMessages(oobDidManager);

    final receivedMessageCompleter = Completer<void>();
    channel.listen((message) {
      if (message.type.toString() == 'https://example.com/persistent') {
        streamMessage = message.body;
        receivedMessageCompleter.complete();
      }
    });

    final sendMessageDid = await bobSDK.generateDid();
    final senderDidDocument = await sendMessageDid.getDidDocument();

    await bobSDK.mediator.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/persistent'),
        from: senderDidDocument.id,
        to: [oobInvitationMessage.from],
        body: {'persistent': 'message'},
      ),
      senderDidManager: sendMessageDid,
      recipientDidDocument: oobDidDocument,
      next: oobInvitationMessage.from,
    );

    await receivedMessageCompleter.future;
    expect(streamMessage, {'persistent': 'message'});
    await channel.dispose();

    final fetchedMessages = await aliceSDK.fetchMessages(
      did: oobDidDocument.id,
      deleteOnRetrieve: false,
    );

    final persistentMessages = fetchedMessages
        .where(
          (msg) =>
              msg.plainTextMessage.type.toString() ==
              'https://example.com/persistent',
        )
        .toList();

    expect(persistentMessages.length, 1);
    expect(persistentMessages.first.plainTextMessage.body, {
      'persistent': 'message',
    });
  }, skip: 'check');
}
