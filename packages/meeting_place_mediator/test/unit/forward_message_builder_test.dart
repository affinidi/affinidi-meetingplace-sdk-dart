import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/src/core/mediator/forward_message_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMediatorClient extends Mock implements MediatorClient {}

void main() {
  group('ForwardMessageBuilder.build', () {
    late EncryptedMessage encryptedMessage;
    late DidDocument senderDidDocument;
    late DidDocument mediatorDidDocument;
    late MediatorClient mediatorClient;
    const next = 'did:key:z6MkTestRecipient';

    setUp(() {
      encryptedMessage = EncryptedMessage(
        cipherText: Uint8List.fromList('encrypted_content'.codeUnits),
        authenticationTag: Uint8List.fromList('auth_tag'.codeUnits),
        initializationVector: Uint8List.fromList('iv'.codeUnits),
        protected: 'protected_header',
        recipients: [],
      );

      senderDidDocument = DidDocument.create(
        id: 'did:key:z6MkTestSender',
      );

      mediatorDidDocument = DidDocument.create(
        id: 'did:key:z6MkTestMediator',
      );

      mediatorClient = MockMediatorClient();
      when(() => mediatorClient.mediatorDidDocument)
          .thenReturn(mediatorDidDocument);
    });

    test('builds forward message with required fields', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      expect(result.id, isNotEmpty);
      expect(result.from, equals(senderDidDocument.id));
      expect(result.to, contains(mediatorDidDocument.id));
      expect(result.next, equals(next));
      expect(result.attachments, hasLength(1));
    });

    test('sets ephemeral to false by default', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      expect(result['ephemeral'], equals(false));
    });

    test('sets ephemeral to true when specified', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
        ephemeral: true,
      );

      expect(result['ephemeral'], equals(true));
    });

    test('sets ephemeral to false when explicitly specified', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
        ephemeral: false,
      );

      expect(result['ephemeral'], equals(false));
    });

    test('does not set expiresTime when forwardExpiryInSeconds is null', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      expect(result.expiresTime, isNull);
    });

    test('sets expiresTime when forwardExpiryInSeconds is provided', () {
      final beforeCreation = DateTime.now().toUtc();

      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
        forwardExpiryInSeconds: 3600,
      );

      final afterCreation = DateTime.now().toUtc();

      expect(result.expiresTime, isNotNull);

      final expectedMin = beforeCreation.add(const Duration(seconds: 3600));
      final expectedMax = afterCreation.add(const Duration(seconds: 3600));

      expect(
        result.expiresTime!
            .isAfter(expectedMin.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        result.expiresTime!
            .isBefore(expectedMax.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('creates attachment with correct media type', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      expect(result.attachments?.first.mediaType, equals('application/json'));
    });

    test('creates attachment with base64 encoded data', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      final attachment = result.attachments!.first;
      expect(attachment.data?.base64, isNotEmpty);
      // Base64 data should not contain padding
      expect(attachment.data?.base64?.endsWith('='), isFalse);
    });

    test('generates unique IDs for different messages', () {
      final result1 = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      final result2 = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
      );

      expect(result1.id, isNot(equals(result2.id)));
    });

    test('builds complete message with all optional parameters', () {
      final result = ForwardMessageBuilder.build(
        encryptedMessage,
        senderDidDocument: senderDidDocument,
        mediatorClient: mediatorClient,
        next: next,
        forwardExpiryInSeconds: 7200,
        ephemeral: true,
      );

      expect(result.id, isNotEmpty);
      expect(result.from, equals(senderDidDocument.id));
      expect(result.to, contains(mediatorDidDocument.id));
      expect(result.next, equals(next));
      expect(result.expiresTime, isNotNull);
      expect(result['ephemeral'], equals(true));
      expect(result.attachments, hasLength(1));
    });
  });
}
