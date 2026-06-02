import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/mediator_integration_fixture.dart';

void main() {
  group('Message receiving and automatic deletion >>', () {
    late MediatorIntegrationFixture fixture;
    late MediatorStreamSubscription subscription;
    late PlainTextMessage messageToSend;
    late DidDocument recipientDidDoc;

    setUp(() async {
      fixture = await MediatorIntegrationFixture.create();

      await fixture.sdk.fetchMessages(
        didManager: fixture.didManagerB,
        deleteOnRetrieve: true,
      );

      final senderDidDoc = await fixture.didManagerA.getDidDocument();
      recipientDidDoc = await fixture.didManagerB.getDidDocument();

      messageToSend = PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://affinidi.com/test/1.0/message'),
        body: {'text': 'Sample message'},
        to: [recipientDidDoc.id],
        from: senderDidDoc.id,
      );

      await fixture.sdk.updateAcl(
        ownerDidManager: fixture.didManagerB,
        acl: AccessListAdd(
          ownerDid: recipientDidDoc.id,
          granteeDids: [senderDidDoc.id],
        ),
      );
    });

    test('Listener receives message even when attached after message was sent',
        () async {
      subscription = await fixture.sdk.subscribeToMessages(fixture.didManagerB);

      await fixture.sdk.sendMessage(
        messageToSend,
        senderDidManager: fixture.didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

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

    test('Message retrievable via fetch', () async {
      await fixture.sdk.sendMessage(
        messageToSend,
        senderDidManager: fixture.didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      subscription = await fixture.sdk.subscribeToMessages(fixture.didManagerB);

      final fetchResult = await fixture.sdk.fetchMessages(
        didManager: fixture.didManagerB,
        deleteOnRetrieve: false,
      );
      final matches =
          fetchResult.where((r) => r.message?.id == messageToSend.id).toList();
      expect(matches.length, equals(1));
      expect(matches.first.message!.id, equals(messageToSend.id));
    });

    test('Message is not deleted if no listener was attached', () async {
      await fixture.sdk.sendMessage(
        messageToSend,
        senderDidManager: fixture.didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      subscription = await fixture.sdk.subscribeToMessages(fixture.didManagerB);
      await Future<void>.delayed(const Duration(seconds: 2));

      final fetchResult = await fixture.sdk.fetchMessages(
        didManager: fixture.didManagerB,
        deleteOnRetrieve: false,
      );

      final actual = fetchResult.firstWhere(
        (r) => r.message?.type == messageToSend.type,
        orElse: () => fail('Message not found'),
      );

      expect(actual.message?.id, equals(messageToSend.id));
    });

    test('Message is deleted after listener processes it', () async {
      subscription = await fixture.sdk.subscribeToMessages(
        fixture.didManagerB,
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

      await fixture.sdk.sendMessage(
        messageToSend,
        senderDidManager: fixture.didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      await messageReceivedCompleter.future;
      await Future<void>.delayed(const Duration(seconds: 2));

      final fetchResult = await fixture.sdk.fetchMessages(
        didManager: fixture.didManagerB,
        deleteOnRetrieve: false,
      );

      final actual =
          fetchResult.where((r) => r.message?.id == messageToSend.id);
      expect(actual.length, isZero);
    });

    test('Message is not deleted if listener throws error', () async {
      subscription = await fixture.sdk.subscribeToMessages(
        fixture.didManagerB,
        options:
            const MediatorStreamSubscriptionOptions(deleteMessageDelay: null),
      );

      final waitForError = Completer<void>();
      subscription.listen((PlainTextMessage msg) {
        if (msg.type.toString() == 'https://affinidi.com/test/1.0/message') {
          throw Exception('Error while processing message');
        }

        return MediatorStreamProcessingResult(keepMessage: false);
      }, onError: (Object e) {
        if (e.toString().contains('Error while processing message')) {
          waitForError.complete();
        }
      });

      await fixture.sdk.sendMessage(
        messageToSend,
        senderDidManager: fixture.didManagerA,
        recipientDidDocument: recipientDidDoc,
      );

      await waitForError.future;
      await Future<void>.delayed(const Duration(seconds: 2));

      final fetchResult = await fixture.sdk.fetchMessages(
        didManager: fixture.didManagerB,
        deleteOnRetrieve: false,
      );

      final matches =
          fetchResult.where((r) => r.message?.id == messageToSend.id).toList();

      expect(matches.isNotEmpty, isTrue);
    });

    test(
      'Subsequent messages are processed even if previous listener threw an '
      'error',
      () async {
        subscription = await fixture.sdk.subscribeToMessages(
          fixture.didManagerB,
          options:
              const MediatorStreamSubscriptionOptions(deleteMessageDelay: null),
        );

        final messageToBeProcessed = PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse(
              'https://affinidi.com/test/1.0/message-to-be-processed'),
          body: messageToSend.body,
          to: messageToSend.to,
          from: messageToSend.from,
        );

        final waitForMessageToBeProcessed = Completer<void>();
        final waitForError = Completer<void>();

        subscription.listen((PlainTextMessage msg) {
          if (msg.type == messageToSend.type) {
            throw Exception('Error while processing message');
          }

          if (msg.type == messageToBeProcessed.type &&
              msg.id == messageToBeProcessed.id) {
            waitForMessageToBeProcessed.complete();
          }

          return MediatorStreamProcessingResult(keepMessage: false);
        }, onError: (Object e) {
          if (e.toString().contains('Error while processing message')) {
            waitForError.complete();
          }
        });

        await fixture.sdk.sendMessage(
          messageToSend,
          senderDidManager: fixture.didManagerA,
          recipientDidDocument: recipientDidDoc,
        );

        await waitForError.future;

        await fixture.sdk.sendMessage(
          messageToBeProcessed,
          senderDidManager: fixture.didManagerA,
          recipientDidDocument: recipientDidDoc,
        );

        await waitForMessageToBeProcessed.future;

        final fetchResult = await fixture.sdk.fetchMessages(
          didManager: fixture.didManagerB,
          deleteOnRetrieve: false,
        );

        final actual =
            fetchResult.where((r) => r.message?.id == messageToBeProcessed.id);

        expect(actual.length, isZero);
      },
    );
  });
}
