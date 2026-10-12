import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/src/core/mediator/message_hash.dart';
import 'package:meeting_place_mediator/src/core/message/trust_task_response_filter.dart';
import 'package:meeting_place_mediator/src/loggers/default_meeting_place_mediator_sdk_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'test_party.dart';

class MockMediatorClient extends Mock implements MediatorClient {}

void main() {
  late TestParty mediator;
  late TestParty peer;
  late TestParty recipient;
  late MockMediatorClient client;
  late TrustTaskResponseFilter filter;

  final responseCreatedTime = DateTime.utc(2026, 10, 12, 9, 30);
  late Map<String, dynamic> trustTaskResponse;
  late Map<String, dynamic> peerMessage;

  setUpAll(() async {
    mediator = await TestParty.create();
    peer = await TestParty.create();
    recipient = await TestParty.create();

    trustTaskResponse = await mediator.authcrypt(
      TrustTaskMessage(
        id: const Uuid().v4(),
        createdTime: responseCreatedTime,
        document: TrustTaskDocument(
          type: AccessListUpdateTask.taskType,
          issuer: mediator.didDocument.id,
          recipient: recipient.didDocument.id,
          payload: const {},
        ),
      ),
      to: recipient,
    );

    peerMessage = await peer.authcrypt(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/app/1.0/hello'),
        from: peer.didDocument.id,
        to: [recipient.didDocument.id],
        body: const {'text': 'hello'},
      ),
      to: recipient,
    );
  });

  setUp(() {
    client = MockMediatorClient();
    when(() => client.mediatorDidDocument).thenReturn(mediator.didDocument);
    when(
      () => client.deleteMessages(messageIds: any(named: 'messageIds')),
    ).thenAnswer((_) async {});

    filter = TrustTaskResponseFilter(
      client: client,
      didManager: recipient.didManager,
      logger: DefaultMeetingPlaceMediatorSDKLogger(
        className: 'TrustTaskResponseFilterTest',
        sdkName: 'test',
      ),
    );
  });

  test('removes mediator Trust Task responses and deletes them', () async {
    final result = await filter.removeResponses([
      trustTaskResponse,
      peerMessage,
    ]);

    expect(result.appMessages, [peerMessage]);
    verify(
      () => client.deleteMessages(messageIds: [hashMessage(trustTaskResponse)]),
    ).called(1);
  });

  test('returns the unpacked responses so fetch can page past them', () async {
    final result = await filter.removeResponses([
      trustTaskResponse,
      peerMessage,
    ]);

    expect(result.responses.single.createdTime, responseCreatedTime);
  });

  test('keeps messages from peers without deleting anything', () async {
    final result = await filter.removeResponses([peerMessage]);

    expect(result.appMessages, [peerMessage]);
    verifyNever(
      () => client.deleteMessages(messageIds: any(named: 'messageIds')),
    );
  });

  test(
    'skips the delete when the mediator already deleted on retrieval',
    () async {
      final result = await filter.removeResponses([
        trustTaskResponse,
        peerMessage,
      ], deletedOnMediator: true);

      expect(result.appMessages, [peerMessage]);
      verifyNever(
        () => client.deleteMessages(messageIds: any(named: 'messageIds')),
      );
    },
  );

  test('still removes the responses when the delete fails', () async {
    when(
      () => client.deleteMessages(messageIds: any(named: 'messageIds')),
    ).thenThrow(Exception('mediator unavailable'));

    final result = await filter.removeResponses([
      trustTaskResponse,
      peerMessage,
    ]);

    expect(result.appMessages, [peerMessage]);
  });
}
