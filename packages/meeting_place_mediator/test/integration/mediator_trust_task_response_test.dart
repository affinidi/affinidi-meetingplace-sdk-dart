import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/mediator_integration_fixture.dart';

// Accept both wrapping types, as apps combining several protocols do, so a
// Trust Task response (authcrypt, unsigned) would unpack if it were not
// filtered out.
const _wrappingTypes = [
  MessageWrappingType.authcryptPlaintext,
  MessageWrappingType.authcryptSignPlaintext,
];

const _inboxTimeout = Duration(seconds: 20);
const _inboxPollInterval = Duration(milliseconds: 250);

void main() {
  late MediatorIntegrationFixture fixture;

  setUp(() async {
    fixture = await MediatorIntegrationFixture.create();
  });

  Future<List<String>> inboxOfA() async {
    final client = await fixture.sdk.authenticateWithDid(fixture.didManagerA);
    return client.listInboxMessageIds();
  }

  // The mediator stores its response after answering the request, so poll
  // instead of reading the inbox once.
  Future<void> waitForInboxOfA(
    bool Function(List<String> ids) condition,
  ) async {
    final deadline = DateTime.now().add(_inboxTimeout);
    while (!condition(await inboxOfA())) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Inbox did not reach the expected state in time');
      }
      await Future<void>.delayed(_inboxPollInterval);
    }
  }

  Future<void> grantBAccessToA() async {
    final ownerDid = (await fixture.didManagerA.getDidDocument()).id;
    final granteeDid = (await fixture.didManagerB.getDidDocument()).id;

    await fixture.sdk.updateAcl(
      ownerDidManager: fixture.didManagerA,
      acl: AccessListAdd(ownerDid: ownerDid, granteeDids: [granteeDid]),
    );
  }

  void expectNoTrustTaskResponses(Iterable<PlainTextMessage?> messages) {
    expect(
      messages.whereType<PlainTextMessage>().where(
        TrustTaskMessage.isTrustTask,
      ),
      isEmpty,
    );
  }

  test('fetch skips Trust Task responses and deletes them', () async {
    await grantBAccessToA();
    await waitForInboxOfA((ids) => ids.isNotEmpty);

    final results = await fixture.sdk.fetchMessages(
      FetchMessagesRequest(
        didManager: fixture.didManagerA,
        expectedMessageWrappingTypes: _wrappingTypes,
      ),
    );

    expectNoTrustTaskResponses(results.map((result) => result.message));
    expect(await inboxOfA(), isEmpty);
  });

  test('fetch with deleteOnRetrieve skips Trust Task responses', () async {
    await grantBAccessToA();
    await waitForInboxOfA((ids) => ids.isNotEmpty);

    final results = await fixture.sdk.fetchMessages(
      FetchMessagesRequest(
        didManager: fixture.didManagerA,
        deleteOnRetrieve: true,
        expectedMessageWrappingTypes: _wrappingTypes,
      ),
    );

    expectNoTrustTaskResponses(results.map((result) => result.message));
    expect(await inboxOfA(), isEmpty);
  });

  test('subscription skips Trust Task responses and deletes them', () async {
    final recipientDidDoc = await fixture.didManagerA.getDidDocument();
    final senderDidDoc = await fixture.didManagerB.getDidDocument();

    final sentinel = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://affinidi.com/test/1.0/message'),
      to: [recipientDidDoc.id],
      from: senderDidDoc.id,
      body: {'text': 'sentinel'},
    );

    final subscription = await fixture.sdk.subscribeToMessages(
      fixture.didManagerA,
      options: const MediatorStreamSubscriptionOptions(
        expectedMessageWrappingTypes: _wrappingTypes,
      ),
    );

    // The mediator also streams its own status messages, so collect
    // everything up to the sentinel and check none is a Trust Task response.
    final received = <PlainTextMessage>[];
    final sentinelReceived = Completer<void>();
    subscription.listen((PlainTextMessage msg) {
      received.add(msg);
      if (msg.id == sentinel.id && !sentinelReceived.isCompleted) {
        sentinelReceived.complete();
      }
      return MediatorStreamProcessingResult(keepMessage: false);
    });

    // Granted after subscribing, so the response arrives over the socket.
    await grantBAccessToA();

    await fixture.sdk.sendMessage(
      MediatorMessageRequest(
        message: sentinel,
        senderDidManager: fixture.didManagerB,
        recipientDidDocument: recipientDidDoc,
      ),
    );

    await sentinelReceived.future.timeout(_inboxTimeout);
    // The response must not linger: an unfiltered one would have been
    // emitted, an undelivered one would still be in the inbox.
    await waitForInboxOfA((ids) => ids.isEmpty);
    await subscription.dispose();

    expect(received.where(TrustTaskMessage.isTrustTask), isEmpty);
  });
}
