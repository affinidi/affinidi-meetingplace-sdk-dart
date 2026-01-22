import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:test/test.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import 'fixture/sdk_fixture.dart';

void main() {
  late MeetingPlaceMediatorSDK sdk;
  late DidManager didManagerA;
  late DidManager didManagerB;

  setUp(() async {
    final aliceWallet = PersistentWallet(InMemoryKeyStore());
    sdk = MeetingPlaceMediatorSDK(
      mediatorDid: getMediatorDid(),
      didResolver: UniversalDIDResolver(),
    );

    final keyPairA = await aliceWallet.generateKey();
    didManagerA = DidKeyManager(wallet: aliceWallet, store: InMemoryDidStore());

    await didManagerA.addVerificationMethod(keyPairA.id);

    final keyPairB = await aliceWallet.generateKey();
    didManagerB = DidKeyManager(wallet: aliceWallet, store: InMemoryDidStore());

    await didManagerB.addVerificationMethod(keyPairB.id);
  });

  test(
    'handles multiple subscriptions to mediator gracefully returning a new instance',
    () async {
      final subscriptionA = await sdk.subscribeToMessages(didManagerA);
      final subscriptionB = await sdk.subscribeToMessages(didManagerA);

      expect(subscriptionA, isNot(equals(subscriptionB)));
    },
  );

  test(
    'Multiple subscriptions to mediator with the same did',
    () async {
      final clientA = await sdk.authenticateWithDid(didManagerA);
      final clientB = await sdk.authenticateWithDid(didManagerA);
      expect(clientA, equals(clientB));
    },
  );

  test('Uses new mediator session if did is not cached', () async {
    final sessionA = await sdk.authenticateWithDid(didManagerA);
    final sessionB = await sdk.authenticateWithDid(didManagerB);
    expect(sessionA, isNot(equals(sessionB)));
  });

  // test('Uses new mediator session if mediator did changes', () async {
  //   final sessionA = await sdk.authenticateWithDid(didManagerA);
  //   sdk.mediatorDid = Platform.environment['MEDIATOR_DID_ALTERNATIVE'] ??
  //       (throw Exception('MEDIATOR_DID_ALTERNATIVE not set in environment'));

  //   final sessionB = await sdk.authenticateWithDid(didManagerA);
  //   expect(sessionA, isNot(equals(sessionB)));
  // });

  test('Update ACL to publish', () async {
    final didDoc = await didManagerA.getDidDocument();
    await sdk.updateAcl(
      ownerDidManager: didManagerA,
      acl: AclSet.toPublic(ownerDid: didDoc.id),
    );
  });

  group('Message receiving and automatic deletion >>', () {
    late MediatorStreamSubscription subscription;
    late PlainTextMessage messageToSend;
    late DidDocument recipientDidDoc;

    setUp(() async {
      // Clear queue
      await sdk.fetchMessages(didManager: didManagerB, deleteOnRetrieve: true);

      final senderDidDoc = await didManagerA.getDidDocument();
      recipientDidDoc = await didManagerB.getDidDocument();

      messageToSend = PlainTextMessage(
        id: Uuid().v4(),
        type: Uri.parse('https://affinidi.com/test/1.0/message'),
        body: {'text': 'Sample message'},
        to: [recipientDidDoc.id],
        from: senderDidDoc.id,
      );

      await sdk.updateAcl(
          ownerDidManager: didManagerB,
          acl: AccessListAdd(
            ownerDid: recipientDidDoc.id,
            granteeDids: [senderDidDoc.id],
          ));
    });

    test('Listener receives message even when attached after message was sent',
        () async {
      // Open subscription to mediator
      subscription = await sdk.subscribeToMessages(didManagerB);

      // Send message before listener was attached to subscription
      await sdk.sendMessage(
        messageToSend,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      // Attach listener
      final waitForMessage = Completer<PlainTextMessage>();
      subscription.listen((PlainTextMessage msg) {
        if (msg.type.toString() == 'https://affinidi.com/test/1.0/message') {
          waitForMessage.complete(msg);
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      });

      final actual = await waitForMessage.future;
      expect(actual.id, equals(messageToSend.id));
    });

    test('''Listener receives message even when subscription opened
        after message was sent''', () async {
      // Send message before subscription was opened
      await sdk.sendMessage(
        messageToSend,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      // Open subscription to mediator
      subscription = await sdk.subscribeToMessages(didManagerB);

      // Attach listener to subscription
      final waitForMessage = Completer<PlainTextMessage>();
      subscription.listen((PlainTextMessage msg) {
        if (msg.type.toString() == 'https://affinidi.com/test/1.0/message') {
          waitForMessage.complete(msg);
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      });

      final actual = await waitForMessage.future;
      expect(actual.id, equals(messageToSend.id));
    });

    test('Message is not deleted if no listener was attached', () async {
      await sdk.sendMessage(
        messageToSend,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      subscription = await sdk.subscribeToMessages(didManagerB);
      await Future.delayed(const Duration(seconds: 2));

      final fetchResult = await sdk.fetchMessages(
        didManager: didManagerB,
        deleteOnRetrieve: false,
      );

      final actual = fetchResult.firstWhere(
        (r) => r.message?.type == messageToSend.type,
        orElse: () => fail('Message not found'),
      );

      expect(actual.message?.id, equals(messageToSend.id));
    });

    test('Message is deleted after listener processes it', () async {
      // Send message
      await sdk.sendMessage(
        messageToSend,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      // Open subscription to mediator and attach listener
      subscription = await sdk.subscribeToMessages(
        didManagerB,
        options:
            const MediatorStreamSubscriptionOptions(deleteMessageDelay: null),
      );

      final messageReceivedCompleter = Completer<void>();
      subscription.listen((PlainTextMessage msg) {
        if (msg.type == messageToSend.type) {
          messageReceivedCompleter.complete();
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      });

      await messageReceivedCompleter.future;
      await Future.delayed(const Duration(seconds: 2));

      final fetchResult = await sdk.fetchMessages(
        didManager: didManagerB,
        deleteOnRetrieve: false,
      );

      final actual =
          fetchResult.where((r) => r.message?.id == messageToSend.id);

      expect(actual.length, isZero);
    });

    test('Message is not deleted if listener throws error', () async {
      // Send message
      await sdk.sendMessage(
        messageToSend,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      // Open subscription to mediator and attach listener that throws error
      subscription = await sdk.subscribeToMessages(didManagerB,
          options: MediatorStreamSubscriptionOptions(deleteMessageDelay: null));

      final waitForError = Completer<void>();
      subscription.listen((PlainTextMessage msg) {
        if (msg.type.toString() == 'https://affinidi.com/test/1.0/message') {
          throw Exception('Error while processing message');
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      }, onError: (e) {
        if (e.toString().contains('Error while processing message')) {
          waitForError.complete();
        }
      });

      // Wait for error and add delay to ensure deletion would have happened
      await waitForError.future;
      await Future.delayed(const Duration(seconds: 2));

      // Check that message is still in the queue
      final fetchResult = await sdk.fetchMessages(
          didManager: didManagerB, deleteOnRetrieve: false);

      expect(fetchResult.first.message?.id, equals(messageToSend.id));
    });

    test('''Subsequent messages are processed even if previous
        listener threw an error''', () async {
      // Send message
      await sdk.sendMessage(
        messageToSend,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      // Open subscription to mediator and attach listener that throws error
      subscription = await sdk.subscribeToMessages(didManagerB,
          options: MediatorStreamSubscriptionOptions(deleteMessageDelay: null));

      final waitForError = Completer<void>();
      subscription.listen((PlainTextMessage msg) {
        if (msg.type.toString() == 'https://affinidi.com/test/1.0/message') {
          throw Exception('Error while processing message');
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      }, onError: (e) {
        if (e.toString().contains('Error while processing message')) {
          waitForError.complete();
        }
      });

      final messageToBeProcessed = PlainTextMessage(
        id: Uuid().v4(),
        type:
            Uri.parse('https://affinidi.com/test/1.0/message-to-be-processed'),
        body: messageToSend.body,
        to: messageToSend.to,
        from: messageToSend.from,
      );

      await sdk.sendMessage(
        messageToBeProcessed,
        senderDidManager: didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      // Wait for error and add delay to ensure deletion would have happened
      await waitForError.future;
      await Future.delayed(const Duration(seconds: 2));

      // Check that processed message is removed from queue
      final fetchResult = await sdk.fetchMessages(
          didManager: didManagerB, deleteOnRetrieve: false);

      final actual =
          fetchResult.where((r) => r.message?.id == messageToBeProcessed.id);

      expect(actual.length, isZero);
    });
  });
}
