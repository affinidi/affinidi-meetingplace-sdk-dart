import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:meeting_place_mediator/src/core/mediator/message_hash.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../message/test_party.dart';

class MockMediatorClient extends Mock implements MediatorClient {}

class MockStreamSubscription extends Mock
    implements StreamSubscription<dynamic> {}

void main() {
  late TestParty mediator;
  late TestParty peer;
  late TestParty recipient;
  late MockMediatorClient client;
  late void Function(Map<String, dynamic>) deliver;
  late MediatorStreamSubscription subscription;
  late List<PlainTextMessage> received;

  late Map<String, dynamic> trustTaskResponse;
  late PlainTextMessage peerPlainTextMessage;
  late Map<String, dynamic> peerMessage;

  setUpAll(() async {
    mediator = await TestParty.create();
    peer = await TestParty.create();
    recipient = await TestParty.create();

    trustTaskResponse = await mediator.authcrypt(
      TrustTaskMessage(
        id: const Uuid().v4(),
        document: TrustTaskDocument(
          type: AccessListUpdateTask.taskType,
          issuer: mediator.didDocument.id,
          recipient: recipient.didDocument.id,
          payload: const {},
        ),
      ),
      to: recipient,
    );

    peerPlainTextMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse('https://example.com/app/1.0/hello'),
      from: peer.didDocument.id,
      to: [recipient.didDocument.id],
      body: const {'text': 'hello'},
    );
    peerMessage = await peer.authcrypt(peerPlainTextMessage, to: recipient);
  });

  setUp(() async {
    client = MockMediatorClient();
    when(() => client.mediatorDidDocument).thenReturn(mediator.didDocument);
    when(
      () => client.deleteMessages(messageIds: any(named: 'messageIds')),
    ).thenAnswer((_) async {});
    when(
      () =>
          client.listenForIncomingMessages(any(), onDone: any(named: 'onDone')),
    ).thenAnswer((invocation) {
      deliver =
          invocation.positionalArguments.first
              as void Function(Map<String, dynamic>);
      return MockStreamSubscription();
    });

    subscription = MediatorStreamSubscription(
      client: client,
      didManager: recipient.didManager,
      deleteMessageDelay: null,
      messageWrappingTypes: const [MessageWrappingType.authcryptPlaintext],
    );
    await subscription.initialize();

    received = [];
  });

  tearDown(() async {
    when(() => client.disconnect()).thenAnswer((_) async {});
    await subscription.dispose();
  });

  test('skips a Trust Task response and deletes it via the message '
      'queue', () async {
    final peerMessageReceived = Completer<void>();
    subscription.listen((message) {
      received.add(message);
      peerMessageReceived.complete();
      return MediatorStreamProcessingResult(keepMessage: true);
    });

    deliver(trustTaskResponse);
    deliver(peerMessage);
    await peerMessageReceived.future;
    await untilCalled(
      () => client.deleteMessages(messageIds: any(named: 'messageIds')),
    );

    expect(received.map((message) => message.id), [peerPlainTextMessage.id]);
    verify(
      () => client.deleteMessages(messageIds: [hashMessage(trustTaskResponse)]),
    ).called(1);
  });
}
