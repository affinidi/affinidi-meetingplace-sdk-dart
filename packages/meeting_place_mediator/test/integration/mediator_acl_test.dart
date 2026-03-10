import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/mediator_integration_fixture.dart';

void main() {
  late MediatorIntegrationFixture fixture;

  setUp(() async {
    fixture = await MediatorIntegrationFixture.create();
  });

  test('Update ACL to public', () async {
    final recipientDidDoc = await fixture.didManagerA.getDidDocument();
    final senderDidDoc = await fixture.didManagerB.getDidDocument();

    final testMessage = PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://affinidi.com/test/1.0/message'),
        to: [recipientDidDoc.id],
        from: senderDidDoc.id,
        body: {'text': 'Sample message'});

    await fixture.sdk.updateAcl(
      ownerDidManager: fixture.didManagerA,
      acl: AclSet.toPublic(ownerDid: recipientDidDoc.id),
    );

    final subscription =
        await fixture.sdk.subscribeToMessages(fixture.didManagerA);

    final waitForMessage = Completer<PlainTextMessage>();
    subscription.listen((PlainTextMessage msg) {
      if (msg.type == testMessage.type && msg.id == testMessage.id) {
        waitForMessage.complete(msg);
        subscription.dispose();
        return MediatorStreamProcessingResult(keepMessage: false);
      }
      return MediatorStreamProcessingResult(keepMessage: true);
    });

    await fixture.sdk.sendMessage(
      testMessage,
      senderDidManager: fixture.didManagerB,
      recipientDidDocument: recipientDidDoc,
    );

    final receivedMessage = await waitForMessage.future;
    expect(receivedMessage.from, senderDidDoc.id);
    expect(receivedMessage.to, contains(recipientDidDoc.id));
  });

  test('Update ACL to allow only specific DID to send message', () async {
    final recipientDidDoc = await fixture.didManagerA.getDidDocument();
    final senderDidDoc = await fixture.didManagerB.getDidDocument();

    final testMessage = PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://affinidi.com/test/1.0/message'),
        to: [recipientDidDoc.id],
        from: senderDidDoc.id,
        body: {'text': 'Sample message'});

    await fixture.sdk.updateAcl(
      ownerDidManager: fixture.didManagerA,
      acl: AccessListAdd(
        ownerDid: recipientDidDoc.id,
        granteeDids: [senderDidDoc.id],
      ),
    );

    final subscription =
        await fixture.sdk.subscribeToMessages(fixture.didManagerA);

    final waitForMessage = Completer<PlainTextMessage>();
    subscription.listen((PlainTextMessage msg) {
      if (msg.type == testMessage.type && msg.id == testMessage.id) {
        waitForMessage.complete(msg);
        subscription.dispose();
        return MediatorStreamProcessingResult(keepMessage: false);
      }
      return MediatorStreamProcessingResult(keepMessage: true);
    });

    await fixture.sdk.sendMessage(
      testMessage,
      senderDidManager: fixture.didManagerB,
      recipientDidDocument: recipientDidDoc,
    );

    final receivedMessage = await waitForMessage.future;
    expect(receivedMessage.from, senderDidDoc.id);
    expect(receivedMessage.to, contains(recipientDidDoc.id));

    expect(
        () => fixture.sdk.sendMessage(
              testMessage,
              senderDidManager: fixture.didManagerC,
              recipientDidDocument: recipientDidDoc,
            ),
        throwsA(isA<MeetingPlaceMediatorSDKException>().having(
          (e) => e.code,
          'code',
          MeetingPlaceMediatorSDKErrorCode.sendMessageError.value,
        )));
  });
}
