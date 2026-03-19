import 'dart:async';
import 'dart:io';

import 'package:matrix/matrix.dart' as matrix;
import 'package:test/test.dart';

import '../utils/group_chat_fixture.dart';
import '../../utils/sdk.dart';

void main() {
  const megolmAlgorithm = 'm.megolm.v1.aes-sha2';

  final skipReason =
      Platform.environment['VODOZEMAC_LIBRARY_PATH'] == null &&
          getVodozemacLibraryPath() == null
      ? 'Set VODOZEMAC_LIBRARY_PATH to a built native vodozemac library directory to run Matrix encryption integration tests.'
      : null;

  if (skipReason != null) {
    test(
      'group matrix messages are delivered as encrypted events',
      () {},
      skip: skipReason,
    );
    return;
  }

  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
  });

  test('group matrix messages are delivered as encrypted events', () async {
    final message =
        'encrypted-group-message-${DateTime.now().microsecondsSinceEpoch}';
    final eventCompleter = Completer<matrix.Event>();

    final subscription = fixture.bobSDK.subscribeToMatrixTimeline().listen((
      event,
    ) {
      final cameFromEncryptedEvent =
          event.originalSource?.type == matrix.EventTypes.Encrypted ||
          event.type == matrix.EventTypes.Encrypted;

      if (event.roomId == fixture.matrixRoomId &&
          event.content['body'] == message &&
          cameFromEncryptedEvent &&
          !eventCompleter.isCompleted) {
        eventCompleter.complete(event);
      }
    });

    try {
      await fixture.aliceSDK.sendGroupMessageOverMatrix(
        roomId: fixture.matrixRoomId,
        message: message,
        senderDid: fixture.aliceDid,
        recipientDid: fixture.groupDid,
      );

      final receivedEvent = await eventCompleter.future.timeout(
        const Duration(seconds: 30),
      );
      final encryptedSource = receivedEvent.originalSource;

      expect(receivedEvent.roomId, fixture.matrixRoomId);
      expect(receivedEvent.type, matrix.EventTypes.Message);
      expect(receivedEvent.content['body'], message);
      expect(receivedEvent.content['msgtype'], 'm.text');
      expect(encryptedSource, isNotNull);
      expect(
        encryptedSource?.type ?? receivedEvent.type,
        matrix.EventTypes.Encrypted,
      );
      expect(encryptedSource?.content['algorithm'], megolmAlgorithm);
      expect(encryptedSource?.content['ciphertext'], isA<String>());
      expect(
        (encryptedSource?.content['ciphertext'] as String).isNotEmpty,
        isTrue,
      );
      expect(encryptedSource?.content['session_id'], isA<String>());
      expect(
        (encryptedSource?.content['session_id'] as String).isNotEmpty,
        isTrue,
      );
      expect(encryptedSource?.content['sender_key'], isA<String>());
      expect(
        (encryptedSource?.content['sender_key'] as String).isNotEmpty,
        isTrue,
      );
      expect(encryptedSource?.content.containsKey('body'), isFalse);
    } finally {
      await subscription.cancel();
    }
  });
}
