import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  late DidManager aliceDID;
  late DidDocument aliceDidDoc;

  late DidManager bobDID;
  late DidDocument bobDidDoc;

  Future<void> clearMessageQueue(DidDocument didDoc) async {
    await aliceSDK.fetchMessages(did: aliceDidDoc.id, deleteOnRetrieve: true);
  }

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();

    aliceDID = await aliceSDK.generateDid();
    aliceDidDoc = await aliceDID.getDidDocument();

    bobDID = await bobSDK.generateDid();
    bobDidDoc = await bobDID.getDidDocument();

    await aliceSDK.mediator.updateAcl(
      ownerDidManager: aliceDID,
      acl: AccessListAdd(ownerDid: aliceDidDoc.id, granteeDids: [bobDidDoc.id]),
    );

    await clearMessageQueue(aliceDidDoc);
    await clearMessageQueue(bobDidDoc);
  });

  Future<void> sendMessageFromBobToAlice([
    String message = 'Hello World',
  ]) async {
    await bobSDK.sendMessage(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/test'),
        from: bobDidDoc.id,
        to: [aliceDidDoc.id],
        body: {'message': message},
      ),
      senderDid: bobDidDoc.id,
      recipientDid: aliceDidDoc.id,
    );
  }

  test('successfully subscribes to mediator and receives messages', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);

    final messageCompleter = Completer<MediatorMessage>();
    subscription.listen((message) {
      if (message.plainTextMessage.isOfType('https://example.com/test')) {
        messageCompleter.complete(message);
      }
      return MediatorStreamProcessingResult(keepMessage: false);
    });

    await sendMessageFromBobToAlice();

    final receivedMessage = await messageCompleter.future.timeout(
      const Duration(seconds: 10),
    );

    expect(receivedMessage.plainTextMessage.body!['message'], 'Hello World');
    await subscription.dispose();

    await sendMessageFromBobToAlice();
  });

  test('returns closed subscription after dispose', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);
    expect(subscription.isClosed, false);

    await subscription.dispose();
    expect(subscription.isClosed, true);
  });

  test('supports multiple listeners on the same subscription', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);

    final listener1Completer = Completer<MediatorMessage>();
    final listener2Completer = Completer<MediatorMessage>();

    subscription.listen((message) {
      if (message.plainTextMessage.isOfType('https://example.com/test')) {
        listener1Completer.complete(message);
      }
      return MediatorStreamProcessingResult(keepMessage: false);
    });

    subscription.listen((message) {
      if (message.plainTextMessage.isOfType('https://example.com/test')) {
        listener2Completer.complete(message);
      }
      return MediatorStreamProcessingResult(keepMessage: false);
    });

    await sendMessageFromBobToAlice();

    final message1 = await listener1Completer.future.timeout(
      const Duration(seconds: 10),
    );

    final message2 = await listener2Completer.future.timeout(
      const Duration(seconds: 10),
    );

    expect(message1.plainTextMessage.body!['message'], 'Hello World');
    expect(message2.plainTextMessage.body!['message'], 'Hello World');
    await subscription.dispose();
  });

  test('processes multiple messages successfully', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);

    var messagesReceived = 0;
    final messageCompleter = Completer<void>();

    subscription.listen((message) {
      if (message.plainTextMessage.isOfType('https://example.com/test')) {
        messagesReceived++;
        if (messagesReceived == 2) {
          messageCompleter.complete();
        }
      }
      return MediatorStreamProcessingResult(keepMessage: false);
    });

    await sendMessageFromBobToAlice('message#1');
    await sendMessageFromBobToAlice('message#2');
    await messageCompleter.future.timeout(const Duration(seconds: 10));

    expect(messagesReceived, equals(2));
    await subscription.dispose();
  });

  test('deletes message from mediator after being processed', () async {
    final subscription = await aliceSDK.subscribeToMediator(
      aliceDidDoc.id,
      options: MediatorStreamSubscriptionOptions(
        deleteMessageDelay: const Duration(milliseconds: 200),
      ),
    );

    var messageCount = 0;
    final waitForMessage = Completer<void>();
    subscription.listen((message) {
      if (message.plainTextMessage.isOfType('https://example.com/test')) {
        messageCount++;
        if (messageCount == 3) {
          waitForMessage.complete();
        }
      }
      return MediatorStreamProcessingResult(keepMessage: false);
    });

    await sendMessageFromBobToAlice();
    await sendMessageFromBobToAlice();
    await sendMessageFromBobToAlice();

    await waitForMessage.future.timeout(const Duration(seconds: 10));
    await subscription.dispose();

    // Delay test execution to allow for message deletion to occur
    await Future.delayed(const Duration(seconds: 5));
    final messages = await aliceSDK.fetchMessages(
      did: aliceDidDoc.id,
      deleteOnRetrieve: true,
    );

    expect(messages.length, equals(0));
  });

  test('stream can be accessed multiple times', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);

    final stream1 = subscription.stream;
    final stream2 = subscription.stream;

    expect(stream1, equals(stream2));
    await subscription.dispose();
  });

  test('timeout applies correctly to the stream', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);
    final timeoutCompleter = Completer<bool>();

    subscription.timeout(
      const Duration(milliseconds: 100),
      () => timeoutCompleter.complete(true),
    );

    final timedOut = await timeoutCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    expect(timedOut, isTrue);
    await subscription.dispose();
  });

  test('creates separate subscriptions for different DIDs', () async {
    final otherDidManager = await aliceSDK.generateDid();
    final otherDidDoc = await otherDidManager.getDidDocument();

    final subscription1 = await aliceSDK.subscribeToMediator(aliceDidDoc.id);
    final subscription2 = await aliceSDK.subscribeToMediator(otherDidDoc.id);

    expect(subscription1, isNot(equals(subscription2)));

    await subscription1.dispose();
    await subscription2.dispose();
  });

  test('onDone callback is invoked when stream closes', () async {
    final subscription = await aliceSDK.subscribeToMediator(aliceDidDoc.id);
    final doneCompleter = Completer<bool>();

    subscription.listen((message) {
      return MediatorStreamProcessingResult(keepMessage: false);
    }, onDone: () => doneCompleter.complete(true));

    await subscription.dispose();

    final done = await doneCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    expect(done, isTrue);
  });

  test(
    'deletes messages in queue even after subscription was disposed',
    () async {
      final subscription = await aliceSDK.subscribeToMediator(
        aliceDidDoc.id,
        options: MediatorStreamSubscriptionOptions(
          deleteMessageDelay: const Duration(seconds: 3),
        ),
      );

      var messageCount = 0;
      final waitForMessage = Completer<void>();

      subscription.listen((message) {
        if (message.plainTextMessage.isOfType('https://example.com/test')) {
          messageCount++;
          if (messageCount == 2) {
            waitForMessage.complete();
          }
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      });

      await sendMessageFromBobToAlice('message#1');
      await sendMessageFromBobToAlice('message#2');

      await waitForMessage.future.timeout(const Duration(seconds: 10));

      // Dispose subscription before scheduled deletion
      await subscription.dispose();

      // Wait for scheduled deletion to complete
      await Future.delayed(const Duration(seconds: 5));

      // Verify messages were deleted even though subscription was disposed
      final messages = await aliceSDK.fetchMessages(
        did: aliceDidDoc.id,
        deleteOnRetrieve: false,
      );

      expect(messages.length, equals(0));
    },
  );

  test('invokes onError callback when listener throws exception', () async {
    final subscription = await aliceSDK.subscribeToMediator(
      aliceDidDoc.id,
      options: MediatorStreamSubscriptionOptions(
        deleteMessageDelay: const Duration(seconds: 3),
      ),
    );

    final waitForError = Completer<bool>();
    subscription.listen(
      (message) {
        if (message.plainTextMessage.isOfType('https://example.com/test')) {
          throw Exception('Test error');
        }
        return MediatorStreamProcessingResult(keepMessage: false);
      },
      onError: (e) {
        waitForError.complete(true);
      },
    );

    await sendMessageFromBobToAlice();

    final onErrorExecuted = await waitForError.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );

    expect(onErrorExecuted, isTrue);
  });
}
