import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import '../../utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  test('subscription cares only about related messages', () async {
    // --- Create OOBs ---
    final didManagerA = await aliceSDK.generateDid();
    final didDocA = await didManagerA.getDidDocument();

    final didManagerB = await aliceSDK.generateDid();
    final didDocB = await didManagerB.getDidDocument();

    // --- Reset messages ---
    await aliceSDK.didcomm.fetchMessages(
      did: didDocA.id,
      deleteOnRetrieve: true,
    );

    await aliceSDK.didcomm.fetchMessages(
      did: didDocB.id,
      deleteOnRetrieve: true,
    );

    // --- Send messages ---
    final sendMessageDid = await bobSDK.generateDid();
    final senderDidDocument = await sendMessageDid.getDidDocument();

    await aliceSDK.didcomm.mediator.updateAcl(
      ownerDidManager: didManagerA,
      acl: AccessListAdd(
        ownerDid: didDocA.id,
        granteeDids: [senderDidDocument.id],
      ),
    );

    await aliceSDK.didcomm.mediator.updateAcl(
      ownerDidManager: didManagerB,
      acl: AccessListAdd(
        ownerDid: didDocB.id,
        granteeDids: [senderDidDocument.id],
      ),
    );

    await bobSDK.didcomm.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: senderDidDocument.id,
        to: [didDocA.id],
        body: {'fooA': 'barA'},
      ),
      senderDid: senderDidDocument.id,
      recipientDid: didDocA.id,
    );

    await bobSDK.didcomm.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: senderDidDocument.id,
        to: [didDocB.id],
        body: {'fooB': 'barB'},
      ),
      senderDid: senderDidDocument.id,
      recipientDid: didDocB.id,
    );

    await Future<void>.delayed(const Duration(seconds: 5));

    final messagesA = await aliceSDK.didcomm.fetchMessages(
      did: didDocA.id,
      deleteOnRetrieve: false,
    );

    final targetMessages = messagesA
        .where(
          (mes) =>
              mes.plainTextMessage.type.toString() ==
              'https://example.com/test',
        )
        .toList();

    expect(targetMessages.length, 1);

    final messagesB = await aliceSDK.didcomm.fetchMessages(
      did: didDocB.id,
      deleteOnRetrieve: false,
    );

    final targetMessagesB = messagesB
        .where(
          (mes) =>
              mes.plainTextMessage.type.toString() ==
              'https://example.com/test',
        )
        .toList();

    expect(targetMessagesB.length, 1);
  });

  test('different stream for each mediator session', () async {
    final didManager = await aliceSDK.generateDid();
    final didDoc = await didManager.getDidDocument();

    final didManager2 = await aliceSDK.generateDid();
    final didDoc2 = await didManager2.getDidDocument();

    final channel = await aliceSDK.didcomm.subscribe(didDoc.id);

    final differentChannel = await aliceSDK.didcomm.subscribe(didDoc2.id);

    expect(channel, isNot(equals(differentChannel)));
    await channel.dispose();
    await differentChannel.dispose();
  });
}
