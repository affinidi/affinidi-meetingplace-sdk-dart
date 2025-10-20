import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'fixtures/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  test('sample test', () async {
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

    // --- Subscriptions ---
    final channel = await aliceSDK.mediator.subscribeToMessages(didManagerA);

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

    expect(targetMessages.length, 0);

    final messagesB = await aliceSDK.mediator.fetchMessages(
      didManager: didManagerB,
    );

    final targetMessagesB = messagesB
        .where(
          (mes) => mes.message!.type.toString() == 'https://example.com/test',
        )
        .toList();

    expect(targetMessagesB.length, 1);
    await channel.dispose();
  });

  // test('mediator session returns same stream if already created', () async {
  //   final didManager = await aliceSDK.generateDid();

  //   final channel = await aliceSDK.mediator.subscribeToMessages(didManager);

  //   final existingChannel = await aliceSDK.mediator.subscribeToMessages(
  //     didManager,
  //   );

  //   expect(channel, equals(existingChannel));

  //   await channel.dispose();
  //   await existingChannel.dispose();
  // });

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

  // test('message subscription handles errors gracefully', () async {
  //   final didManager = await aliceSDK.generateDid();

  //   final channel = await aliceSDK.mediator.subscribeToMessages(
  //     didManager,
  //     onMessage: (message) {
  //       throw Exception('Processing error');
  //     },
  //   );

  //   // The stream should still be active even if message processing fails
  //   expect(channel, isNotNull);

  //   channel.dispose();
  // });

  test('SDK can generate multiple unique DIDs', () async {
    final did1 = await aliceSDK.generateDid();
    final did2 = await aliceSDK.generateDid();
    final did3 = await bobSDK.generateDid();

    final didDoc1 = await did1.getDidDocument();
    final didDoc2 = await did2.getDidDocument();
    final didDoc3 = await did3.getDidDocument();

    expect(didDoc1.id, isNot(equals(didDoc2.id)));
    expect(didDoc1.id, isNot(equals(didDoc3.id)));
    expect(didDoc2.id, isNot(equals(didDoc3.id)));
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

  test(
    'connection offer contains vCard of publisher after publishing',
    () async {
      final vCard = VCard(
        values: {
          'n': {'given': 'Alice'},
        },
      );

      final actual = (await aliceSDK.publishOffer(
        offerName: 'Sample',
        vCard: vCard,
        type: SDKConnectionOfferType.invitation,
      ));

      expect(
        actual.connectionOffer.vCard.values,
        equals({
          'n': {'given': 'Alice'},
        }),
      );
    },
  );

  test('connection offer contains vCard of accepter after accepting', () async {
    final actual = (await aliceSDK.publishOffer(
      offerName: 'Sample',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    ));

    final acceptOfferResult = await bobSDK.acceptOffer(
      connectionOffer: actual.connectionOffer,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    expect(
      acceptOfferResult.connectionOffer.vCard.values,
      equals(VCardFixture.bobPrimaryVCard.values),
    );
  });

  test('find offer', () async {
    final offerName = 'Sample';
    final vCardAlice = VCard(
      values: {
        'n': {'given': 'Alice'},
      },
    );

    final actual = (await aliceSDK.publishOffer(
      offerName: offerName,
      vCard: vCardAlice,
      type: SDKConnectionOfferType.invitation,
    ));

    final result = await bobSDK.findOffer(
      mnemonic: actual.connectionOffer.mnemonic,
    );

    expect(
      result.connectionOffer!.offerLink,
      equals(actual.connectionOffer.offerLink),
    );
    expect(result.connectionOffer!.offerName, equals(offerName));
    expect(result.connectionOffer!.vCard.values, equals(vCardAlice.values));
  });

  test('find offer throws not found exception', () async {
    expect(
      () => aliceSDK.findOffer(mnemonic: 'does-not-exist'),
      throwsA(
        predicate((e) {
          return e is MeetingPlaceCoreSDKException &&
              (e.innerException as ConnectionOfferException).errorCode ==
                  ConnectionOfferExceptionCodes.offerNotFoundError.code &&
              (e.innerException as ConnectionOfferException).message ==
                  'Offer not found.';
        }),
      ),
    );
  });
}
