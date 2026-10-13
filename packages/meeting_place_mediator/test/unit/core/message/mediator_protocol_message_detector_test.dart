import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/src/core/message/mediator_protocol_message_detector.dart';
import 'package:meeting_place_mediator/src/loggers/meeting_place_mediator_sdk_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'test_party.dart';

class MockLogger extends Mock implements MeetingPlaceMediatorSDKLogger {}

void main() {
  late TestParty mediator;
  late TestParty recipient;
  late TestParty otherRecipient;
  late MockLogger logger;

  setUpAll(() async {
    mediator = await TestParty.create();
    recipient = await TestParty.create();
    otherRecipient = await TestParty.create();
  });

  setUp(() => logger = MockLogger());

  Future<Map<String, dynamic>> responseFromMediator({required TestParty to}) {
    return mediator.authcrypt(
      TrustTaskMessage(
        id: const Uuid().v4(),
        document: TrustTaskDocument(
          type: AccessListUpdateTask.taskType,
          issuer: mediator.didDocument.id,
          recipient: to.didDocument.id,
          payload: const {},
        ),
      ),
      to: to,
    );
  }

  Future<Map<String, dynamic>> messageFromMediator({required String type}) {
    return mediator.authcrypt(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse(type),
        from: mediator.didDocument.id,
        to: [recipient.didDocument.id],
        body: const {},
      ),
      to: recipient,
    );
  }

  Future<PlainTextMessage?> unpackProtocolMessage(
    Map<String, dynamic> message,
  ) {
    return MediatorProtocolMessageDetector.unpackProtocolMessage(
      message,
      recipientDidManager: recipient.didManager,
      mediatorDid: mediator.didDocument.id,
      logger: logger,
    );
  }

  test('identifies a Trust Task response from the mediator', () async {
    expect(
      await unpackProtocolMessage(await responseFromMediator(to: recipient)),
      isA<PlainTextMessage>().having(
        TrustTaskMessage.isTrustTask,
        'isTrustTask',
        isTrue,
      ),
    );
  });

  test('identifies a message pickup status from the mediator', () async {
    final message = await messageFromMediator(
      type: 'https://didcomm.org/messagepickup/3.0/status',
    );

    expect(
      await unpackProtocolMessage(message),
      isA<PlainTextMessage>().having(
        (m) => m.type.toString(),
        'type',
        'https://didcomm.org/messagepickup/3.0/status',
      ),
    );
  });

  test('does not identify other messages from the mediator', () async {
    final message = await messageFromMediator(
      type: 'https://affinidi.com/test/1.0/message',
    );

    expect(await unpackProtocolMessage(message), isNull);
  });

  test('logs a mediator message it cannot unpack and treats it as an app '
      'message', () async {
    final message = await responseFromMediator(to: otherRecipient);

    expect(await unpackProtocolMessage(message), isNull);
    verify(
      () => logger.warning(any(), name: 'unpackProtocolMessage'),
    ).called(1);
  });

  test('treats a message from a peer claiming to be the mediator as an app '
      'message', () async {
    final peer = await TestParty.create();
    final message = await peer.authcrypt(
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

    final mediatorKeyId = mediator.didDocument.keyAgreement.first.id;
    final header =
        jsonDecode(
              utf8.decode(
                base64Url.decode(
                  base64Url.normalize(message['protected'] as String),
                ),
              ),
            )
            as Map<String, dynamic>;
    header['skid'] = mediatorKeyId;
    header['apu'] = base64Url
        .encode(utf8.encode(mediatorKeyId))
        .replaceAll('=', '');
    message['protected'] = base64Url
        .encode(utf8.encode(jsonEncode(header)))
        .replaceAll('=', '');

    expect(await unpackProtocolMessage(message), isNull);
    verify(
      () => logger.warning(any(), name: 'unpackProtocolMessage'),
    ).called(1);
  });

  test('logs a message that is not encrypted', () async {
    expect(await unpackProtocolMessage({'id': 'plain'}), isNull);
    verify(() => logger.debug(any(), name: '_isSentBy')).called(1);
  });
}
