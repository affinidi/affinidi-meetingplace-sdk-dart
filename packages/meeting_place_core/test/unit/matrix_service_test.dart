import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/generated/fixed_model.dart'
    as matrix_api;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockMatrixRoom extends Mock implements matrix.Room {}

class MockKeyRepository extends Mock implements KeyRepository {}

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class MockDidManager extends Mock implements DidManager {}

class MockDidDocument extends Mock implements DidDocument {}

const didAuthLoginType = 'org.affinidi.login.did_auth';
const matrixCredentialJwt = 'matrix-jwt';
final matrixHomeserver = Uri.parse('http://localhost:9000');

void main() {
  group('MatrixService', () {
    late MockMatrixClient matrixClient;
    late MockMatrixRoom room;
    late MockKeyRepository keyRepository;
    late MockControlPlaneSDK controlPlaneSDK;
    late MockDidManager rootDidManager;
    late MockDidDocument rootDidDoc;
    late MatrixService service;
    late String requestedCredentialHomeserver;

    setUpAll(() {
      registerFallbackValue(
        matrix.AuthenticationUserIdentifier(user: 'fallback-user'),
      );
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(
        MatrixRegistrationCredentialCommand(homeserver: ''),
      );
    });

    setUp(() {
      matrixClient = MockMatrixClient();
      room = MockMatrixRoom();
      keyRepository = MockKeyRepository();
      controlPlaneSDK = MockControlPlaneSDK();
      rootDidManager = MockDidManager();
      rootDidDoc = MockDidDocument();
      requestedCredentialHomeserver = '';
      service = MatrixService(
        matrixClientFactory: (_) async => matrixClient,
        keyRepository: keyRepository,
        controlPlaneSDK: controlPlaneSDK,
      );

      when(() => controlPlaneSDK.didManager).thenReturn(rootDidManager);
      when(() => rootDidDoc.id).thenReturn('did:test:alice');
      when(
        () => rootDidManager.getDidDocument(),
      ).thenAnswer((_) async => rootDidDoc);

      when(
        () => controlPlaneSDK
            .execute<MatrixRegistrationCredentialCommandOutput>(any()),
      ).thenAnswer((invocation) async {
        final cmd =
            invocation.positionalArguments[0]
                as MatrixRegistrationCredentialCommand;
        requestedCredentialHomeserver = cmd.homeserver;
        return MatrixRegistrationCredentialCommandOutput(
          credential: matrixCredentialJwt,
          did: 'did:test:alice',
        );
      });

      when(
        () => matrixClient.init(
          waitForFirstSync: any(named: 'waitForFirstSync'),
          waitUntilLoadCompletedLoaded: any(
            named: 'waitUntilLoadCompletedLoaded',
          ),
          newToken: any(named: 'newToken'),
          newHomeserver: any(named: 'newHomeserver'),
          newUserID: any(named: 'newUserID'),
          newDeviceID: any(named: 'newDeviceID'),
          newOlmAccount: any(named: 'newOlmAccount'),
        ),
      ).thenAnswer((_) async {});

      when(() => matrixClient.logout()).thenAnswer((_) async {});
      when(() => matrixClient.homeserver).thenReturn(matrixHomeserver);
      when(
        () => keyRepository.saveMatrixLoginCredential(jwt: any(named: 'jwt')),
      ).thenAnswer((_) async {});
      when(
        () => keyRepository.getMatrixLoginCredential(),
      ).thenAnswer((_) async => matrixCredentialJwt);
      when(
        () => keyRepository.removeMatrixLoginCredential(),
      ).thenAnswer((_) async {});
      when(() => matrixClient.accessToken).thenReturn(null);
      when(() => matrixClient.userID).thenReturn(null);
      when(() => matrixClient.deviceID).thenReturn(null);
      when(() => matrixClient.encryptionEnabled).thenReturn(false);
    });

    test(
      'refreshStoredLoginCredential fetches and stores a JWT after registration',
      () async {
        await service.refreshStoredLoginCredential();

        expect(requestedCredentialHomeserver, 'localhost:9000');
        verify(
          () =>
              keyRepository.saveMatrixLoginCredential(jwt: matrixCredentialJwt),
        ).called(1);
      },
    );

    test(
      'login hashes the device token before using it as Matrix deviceId',
      () async {
        const deviceToken = 'push-device-token';
        const did = 'did:test:alice';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();
        final expectedHashedUsername = md5.convert(utf8.encode(did)).toString();

        matrix.AuthenticationIdentifier? capturedIdentifier;

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((invocation) async {
          capturedIdentifier =
              invocation.namedArguments[#identifier]
                  as matrix.AuthenticationIdentifier?;
          return matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          );
        });

        final userId = await service.login(did: did, deviceId: deviceToken);

        expect(userId, '@alice:example.com');
        expect(capturedIdentifier, isA<matrix.AuthenticationUserIdentifier>());
        final identifier =
            capturedIdentifier as matrix.AuthenticationUserIdentifier;
        expect(identifier.user, expectedHashedUsername);
        verify(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: matrixCredentialJwt,
            deviceId: expectedMatrixDeviceId,
          ),
        ).called(1);
        verify(() => keyRepository.getMatrixLoginCredential()).called(1);
      },
    );

    test('createRoomForGroup creates an encrypted group chat', () async {
      const did = 'did:test:alice';
      const deviceToken = 'push-device-token';
      final expectedLocalpart = md5.convert(utf8.encode(did)).toString();
      final expectedMatrixDeviceId = md5
          .convert(utf8.encode(deviceToken))
          .toString();

      when(() => matrixClient.encryptionEnabled).thenReturn(true);
      when(() => matrixClient.accessToken).thenReturn('token');
      when(
        () => matrixClient.userID,
      ).thenReturn('@$expectedLocalpart:example.com');
      when(() => matrixClient.deviceID).thenReturn(expectedMatrixDeviceId);
      when(
        () => matrixClient.createGroupChat(
          enableEncryption: true,
          waitForSync: true,
        ),
      ).thenAnswer((_) async => '!room:example.com');

      final roomId = await service.createRoomForGroup(
        did: did,
        deviceId: deviceToken,
      );

      expect(roomId, '!room:example.com');
      verify(
        () => matrixClient.createGroupChat(
          enableEncryption: true,
          waitForSync: true,
        ),
      ).called(1);
    });

    test('createRoomForGroup requires matrix encryption support', () async {
      const did = 'did:test:alice';
      const deviceToken = 'push-device-token';
      final expectedMatrixDeviceId = md5
          .convert(utf8.encode(deviceToken))
          .toString();

      when(() => matrixClient.encryptionEnabled).thenReturn(false);
      when(() => matrixClient.accessToken).thenReturn(null);
      when(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: any(named: 'token'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => matrix.LoginResponse(
          accessToken: 'token',
          deviceId: expectedMatrixDeviceId,
          userId: '@alice:example.com',
        ),
      );

      expect(
        service.createRoomForGroup(did: did, deviceId: deviceToken),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'sendMessage uses room API so encrypted rooms are handled by matrix',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedLocalpart = md5.convert(utf8.encode(did)).toString();
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(() => matrixClient.accessToken).thenReturn('token');
        when(
          () => matrixClient.userID,
        ).thenReturn('@$expectedLocalpart:example.com');
        when(() => matrixClient.deviceID).thenReturn(expectedMatrixDeviceId);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);
        when(
          () => room.sendTextEvent(
            'hello world',
            txid: any(named: 'txid'),
            parseCommands: false,
            parseMarkdown: false,
            addMentions: true,
          ),
        ).thenAnswer((_) async => r'$event:example.com');

        final eventId = await service.sendMessage(
          roomId: '!room:example.com',
          message: 'hello world',
          did: did,
          deviceId: deviceToken,
        );

        expect(eventId, r'$event:example.com');
        verify(
          () => room.sendTextEvent(
            'hello world',
            txid: any(named: 'txid'),
            parseCommands: false,
            parseMarkdown: false,
            addMentions: true,
          ),
        ).called(1);
      },
    );

    test(
      'sendImageByMxcUri sends m.image with url referencing the provided mxc URI',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        await service.login(did: did, deviceId: deviceToken);

        Map<String, dynamic>? capturedContent;
        when(
          () => room.sendEvent(
            any(),
            txid: any(named: 'txid'),
            inReplyTo: any(named: 'inReplyTo'),
            editEventId: any(named: 'editEventId'),
            threadRootEventId: any(named: 'threadRootEventId'),
            threadLastEventId: any(named: 'threadLastEventId'),
            displayPendingEvent: any(named: 'displayPendingEvent'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = Map<String, dynamic>.from(
            invocation.positionalArguments.first,
          );
          return r'$event:example.com';
        });

        final eventId = await service.sendImageByUri(
          roomId: '!room:example.com',
          uri: 'mxc://localhost:9000/FkQfmXCmuDlXmYDKPuvWsCrg',
          filename: 'photo.jpg',
          mimeType: 'image/jpeg',
          size: 1234,
          width: 640,
          height: 480,
        );

        expect(eventId, r'$event:example.com');
        expect(capturedContent, isNotNull);
        expect(capturedContent!['msgtype'], matrix.MessageTypes.Image);
        expect(
          capturedContent!['url'],
          'mxc://localhost:9000/FkQfmXCmuDlXmYDKPuvWsCrg',
        );
        expect(capturedContent!['body'], 'photo.jpg');
        expect(capturedContent!['filename'], 'photo.jpg');
        expect(capturedContent!['info'], isA<Map>());
        final info = Map<String, dynamic>.from(capturedContent!['info']);
        expect(info['mimetype'], 'image/jpeg');
        expect(info['size'], 1234);
        expect(info['w'], 640);
        expect(info['h'], 480);

        verify(() => room.sendEvent(any(), txid: any(named: 'txid'))).called(1);
      },
    );

    test(
      'sendAudioByMxcUri sends m.audio with url referencing the provided mxc URI',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        await service.login(did: did, deviceId: deviceToken);

        Map<String, dynamic>? capturedContent;
        when(
          () => room.sendEvent(
            any(),
            txid: any(named: 'txid'),
            inReplyTo: any(named: 'inReplyTo'),
            editEventId: any(named: 'editEventId'),
            threadRootEventId: any(named: 'threadRootEventId'),
            threadLastEventId: any(named: 'threadLastEventId'),
            displayPendingEvent: any(named: 'displayPendingEvent'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = Map<String, dynamic>.from(
            invocation.positionalArguments.first,
          );
          return r'$event:example.com';
        });

        final eventId = await service.sendAudioByUri(
          roomId: '!room:example.com',
          mxcUri: 'mxc://localhost:9000/AudioId123',
          filename: 'voice.m4a',
          mimeType: 'audio/mp4',
          size: 4242,
          durationMs: 1000,
        );

        expect(eventId, r'$event:example.com');
        expect(capturedContent, isNotNull);
        expect(capturedContent!['msgtype'], matrix.MessageTypes.Audio);
        expect(capturedContent!['url'], 'mxc://localhost:9000/AudioId123');
        expect(capturedContent!['body'], 'voice.m4a');
        expect(capturedContent!['filename'], 'voice.m4a');
        expect(capturedContent!['info'], isA<Map>());
        final info = Map<String, dynamic>.from(capturedContent!['info']);
        expect(info['mimetype'], 'audio/mp4');
        expect(info['size'], 4242);
        expect(info['duration'], 1000);

        verify(() => room.sendEvent(any(), txid: any(named: 'txid'))).called(1);
      },
    );

    test(
      'sendAttachment uploads base64 audio and dispatches m.audio',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        await service.login(did: did, deviceId: deviceToken);

        when(
          () => matrixClient.uploadContent(
            any(),
            filename: any(named: 'filename'),
            contentType: any(named: 'contentType'),
          ),
        ).thenAnswer((_) async => Uri.parse('mxc://example.com/audio123'));

        Map<String, dynamic>? capturedContent;
        when(
          () => room.sendEvent(
            any(),
            txid: any(named: 'txid'),
            inReplyTo: any(named: 'inReplyTo'),
            editEventId: any(named: 'editEventId'),
            threadRootEventId: any(named: 'threadRootEventId'),
            threadLastEventId: any(named: 'threadLastEventId'),
            displayPendingEvent: any(named: 'displayPendingEvent'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = Map<String, dynamic>.from(
            invocation.positionalArguments.first,
          );
          return r'$event:example.com';
        });

        final attachment = Attachment(
          id: 'attachment-1',
          filename: 'voice.m4a',
          mediaType: 'audio/mp4',
          data: AttachmentData(
            base64: base64Encode([1, 2, 3, 4]),
            json: jsonEncode({'durationMs': 1000}),
          ),
        );

        final result = await service.sendAttachment(
          roomId: '!room:example.com',
          attachment: attachment,
        );

        expect(result.format, AttachmentFormat.matrixAudio.value);
        expect(result.byteCount, 4);
        expect(result.data?.links, [Uri.parse('mxc://example.com/audio123')]);
        expect(capturedContent, isNotNull);
        expect(capturedContent!['msgtype'], matrix.MessageTypes.Audio);
        expect(capturedContent!['url'], 'mxc://example.com/audio123');
        final info = Map<String, dynamic>.from(capturedContent!['info']);
        expect(info['mimetype'], 'audio/mp4');
        expect(info['size'], 4);
        expect(info['duration'], 1000);

        verify(
          () => matrixClient.uploadContent(
            any(),
            filename: 'voice.m4a',
            contentType: 'audio/mp4',
          ),
        ).called(1);
      },
    );

    test(
      'sendAttachment infers audio kind from attachment metadata when format is absent',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        await service.login(did: did, deviceId: deviceToken);

        when(
          () => matrixClient.uploadContent(
            any(),
            filename: any(named: 'filename'),
            contentType: any(named: 'contentType'),
          ),
        ).thenAnswer((_) async => Uri.parse('mxc://example.com/audio999'));

        Map<String, dynamic>? capturedContent;
        when(
          () => room.sendEvent(
            any(),
            txid: any(named: 'txid'),
            inReplyTo: any(named: 'inReplyTo'),
            editEventId: any(named: 'editEventId'),
            threadRootEventId: any(named: 'threadRootEventId'),
            threadLastEventId: any(named: 'threadLastEventId'),
            displayPendingEvent: any(named: 'displayPendingEvent'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = Map<String, dynamic>.from(
            invocation.positionalArguments.first,
          );
          return r'$event:example.com';
        });

        final attachment = Attachment(
          id: 'attachment-metadata-audio',
          filename: 'voice-message',
          data: AttachmentData(
            base64: base64Encode([1, 2, 3]),
            json: jsonEncode({
              'msgtype': matrix.MessageTypes.Audio,
              'durationMs': 640,
            }),
          ),
        );

        final result = await service.sendAttachment(
          roomId: '!room:example.com',
          attachment: attachment,
        );

        expect(result.format, AttachmentFormat.matrixAudio.value);
        expect(capturedContent, isNotNull);
        expect(capturedContent!['msgtype'], matrix.MessageTypes.Audio);
        final info = Map<String, dynamic>.from(capturedContent!['info']);
        expect(info['duration'], 640);
      },
    );

    test(
      'sendAttachment reuses existing image links and dispatches m.image',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        await service.login(did: did, deviceId: deviceToken);

        Map<String, dynamic>? capturedContent;
        when(
          () => room.sendEvent(
            any(),
            txid: any(named: 'txid'),
            inReplyTo: any(named: 'inReplyTo'),
            editEventId: any(named: 'editEventId'),
            threadRootEventId: any(named: 'threadRootEventId'),
            threadLastEventId: any(named: 'threadLastEventId'),
            displayPendingEvent: any(named: 'displayPendingEvent'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = Map<String, dynamic>.from(
            invocation.positionalArguments.first,
          );
          return r'$event:example.com';
        });

        final attachment = Attachment(
          id: 'attachment-2',
          filename: 'photo.jpg',
          mediaType: 'image/jpeg',
          data: AttachmentData(
            links: [Uri.parse('mxc://example.com/image123')],
          ),
        );

        final result = await service.sendAttachment(
          roomId: '!room:example.com',
          attachment: attachment,
        );

        expect(result.format, AttachmentFormat.matrixImage.value);
        expect(result.data?.links, [Uri.parse('mxc://example.com/image123')]);
        expect(capturedContent, isNotNull);
        expect(capturedContent!['msgtype'], matrix.MessageTypes.Image);
        expect(capturedContent!['url'], 'mxc://example.com/image123');

        verifyNever(
          () => matrixClient.uploadContent(
            any(),
            filename: any(named: 'filename'),
            contentType: any(named: 'contentType'),
          ),
        );
      },
    );

    test('sendAttachment throws for unsupported attachments', () async {
      final attachment = Attachment(
        id: 'attachment-3',
        filename: 'document.pdf',
        mediaType: 'application/pdf',
        data: AttachmentData(base64: base64Encode([9, 8, 7])),
      );

      await expectLater(
        () => service.sendAttachment(
          roomId: '!room:example.com',
          attachment: attachment,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('uploadMedia uploads bytes via the active Matrix client', () async {
      const did = 'did:test:alice';
      const deviceToken = 'push-device-token';
      final expectedMatrixDeviceId = md5
          .convert(utf8.encode(deviceToken))
          .toString();

      when(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: any(named: 'token'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => matrix.LoginResponse(
          accessToken: 'token',
          deviceId: expectedMatrixDeviceId,
          userId: '@alice:example.com',
        ),
      );

      await service.login(did: did, deviceId: deviceToken);

      when(
        () => matrixClient.uploadContent(
          any(),
          filename: any(named: 'filename'),
          contentType: any(named: 'contentType'),
        ),
      ).thenAnswer((_) async => Uri.parse('mxc://example.com/media123'));

      final result = await service.uploadMedia(
        Uint8List.fromList([1, 2, 3]),
        filename: 'photo.jpg',
        contentType: 'image/jpeg',
      );

      expect(result, 'mxc://example.com/media123');
      verify(
        () => matrixClient.uploadContent(
          any(),
          filename: 'photo.jpg',
          contentType: 'image/jpeg',
        ),
      ).called(1);
    });

    test('uploadMedia throws when there is no active Matrix session', () async {
      expect(
        () => service.uploadMedia(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<StateError>()),
      );
    });

    test('downloadMediaByUri downloads bytes via matrix getContent', () async {
      const did = 'did:test:alice';
      const deviceToken = 'push-device-token';
      final expectedMatrixDeviceId = md5
          .convert(utf8.encode(deviceToken))
          .toString();

      when(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: any(named: 'token'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => matrix.LoginResponse(
          accessToken: 'token',
          deviceId: expectedMatrixDeviceId,
          userId: '@alice:example.com',
        ),
      );

      when(
        () => matrixClient.getContent(
          'localhost:9000',
          'FkQfmXCmuDlXmYDKPuvWsCrg',
          allowRemote: any(named: 'allowRemote'),
          timeoutMs: any(named: 'timeoutMs'),
        ),
      ).thenAnswer(
        (_) async => matrix_api.FileResponse(
          contentType: 'image/jpeg',
          data: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final response = await service.downloadMediaByUri(
        did: did,
        deviceId: deviceToken,
        uri: 'mxc://localhost:9000/FkQfmXCmuDlXmYDKPuvWsCrg',
      );

      expect(response.contentType, 'image/jpeg');
      expect(response.data, Uint8List.fromList([1, 2, 3]));

      verify(
        () => matrixClient.getContent(
          'localhost:9000',
          'FkQfmXCmuDlXmYDKPuvWsCrg',
          allowRemote: true,
          timeoutMs: null,
        ),
      ).called(1);
    });

    test(
      'downloadAttachment hydrates a plain attachment from its mxc link',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        when(
          () => matrixClient.getContent(
            'localhost:9000',
            'FkQfmXCmuDlXmYDKPuvWsCrg',
            allowRemote: any(named: 'allowRemote'),
            timeoutMs: any(named: 'timeoutMs'),
          ),
        ).thenAnswer(
          (_) async => matrix_api.FileResponse(
            contentType: 'image/jpeg',
            data: Uint8List.fromList([1, 2, 3]),
          ),
        );

        final attachment = Attachment(
          id: 'attachment-1',
          filename: 'photo.jpg',
          data: AttachmentData(
            links: [Uri.parse('mxc://localhost:9000/FkQfmXCmuDlXmYDKPuvWsCrg')],
          ),
        );

        final result = await service.downloadAttachment(
          did: did,
          deviceId: deviceToken,
          attachment: attachment,
        );

        expect(result, isA<Attachment>());
        expect(result.id, 'attachment-1');
        expect(result.filename, 'photo.jpg');
        expect(result.mediaType, 'image/jpeg');
        expect(result.byteCount, 3);
        expect(result.data?.base64, base64Encode([1, 2, 3]));
        expect(result.data?.links, [
          Uri.parse('mxc://localhost:9000/FkQfmXCmuDlXmYDKPuvWsCrg'),
        ]);
      },
    );

    test(
      'downloadAttachment preserves attachment metadata while hydrating from an mxc link',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => matrix.LoginResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        when(
          () => matrixClient.getContent(
            'localhost:9000',
            'media123',
            allowRemote: any(named: 'allowRemote'),
            timeoutMs: any(named: 'timeoutMs'),
          ),
        ).thenAnswer(
          (_) async => matrix_api.FileResponse(
            contentType: 'image/png',
            data: Uint8List.fromList([4, 5, 6, 7]),
          ),
        );

        final attachment = Attachment(
          id: 'matrix-attachment-1',
          filename: 'diagram.png',
          mediaType: 'image/custom',
          data: AttachmentData(
            jws: 'jws-token',
            hash: 'hash-123',
            links: [Uri.parse('mxc://localhost:9000/media123')],
          ),
        );

        final result = await service.downloadAttachment(
          did: did,
          deviceId: deviceToken,
          attachment: attachment,
        );

        expect(result, isA<Attachment>());
        expect(result.id, 'matrix-attachment-1');
        expect(result.filename, 'diagram.png');
        expect(result.mediaType, 'image/custom');
        expect(result.byteCount, 4);
        expect(result.data?.jws, 'jws-token');
        expect(result.data?.hash, 'hash-123');
        expect(result.data?.links, [
          Uri.parse('mxc://localhost:9000/media123'),
        ]);
        expect(result.data?.base64, base64Encode([4, 5, 6, 7]));
      },
    );

    test(
      'downloadAttachment throws when attachment has no mxc link or mxcUri',
      () async {
        const did = 'did:test:alice';
        const deviceToken = 'push-device-token';

        final attachment = Attachment(
          id: 'attachment-without-source',
          filename: 'photo.jpg',
        );

        await expectLater(
          service.downloadAttachment(
            did: did,
            deviceId: deviceToken,
            attachment: attachment,
          ),
          throwsA(isA<StateError>()),
        );

        verifyNever(
          () => matrixClient.getContent(
            any(),
            any(),
            allowRemote: any(named: 'allowRemote'),
            timeoutMs: any(named: 'timeoutMs'),
          ),
        );
      },
    );
  });

  group('MatrixService.ensureLoggedIn', () {
    late MockMatrixClient matrixClient;
    late MockKeyRepository keyRepository;
    late MockControlPlaneSDK controlPlaneSDK;
    late MatrixService service;

    setUp(() {
      matrixClient = MockMatrixClient();
      keyRepository = MockKeyRepository();
      controlPlaneSDK = MockControlPlaneSDK();
      service = MatrixService(
        matrixClientFactory: (_) async => matrixClient,
        keyRepository: keyRepository,
        controlPlaneSDK: controlPlaneSDK,
      );

      when(
        () => matrixClient.init(
          waitForFirstSync: any(named: 'waitForFirstSync'),
          waitUntilLoadCompletedLoaded: any(
            named: 'waitUntilLoadCompletedLoaded',
          ),
          newToken: any(named: 'newToken'),
          newHomeserver: any(named: 'newHomeserver'),
          newUserID: any(named: 'newUserID'),
          newDeviceID: any(named: 'newDeviceID'),
          newOlmAccount: any(named: 'newOlmAccount'),
        ),
      ).thenAnswer((_) async {});
      when(() => matrixClient.logout()).thenAnswer((_) async {});
      when(() => matrixClient.homeserver).thenReturn(matrixHomeserver);
      when(
        () => keyRepository.getMatrixLoginCredential(),
      ).thenAnswer((_) async => matrixCredentialJwt);
      when(
        () => keyRepository.saveMatrixLoginCredential(jwt: any(named: 'jwt')),
      ).thenAnswer((_) async {});
      when(
        () => keyRepository.removeMatrixLoginCredential(),
      ).thenAnswer((_) async {});
      when(() => matrixClient.accessToken).thenReturn(null);
      when(() => matrixClient.userID).thenReturn(null);
      when(() => matrixClient.deviceID).thenReturn(null);
      when(() => matrixClient.encryptionEnabled).thenReturn(false);
    });

    test('logs in when there is no Matrix session', () async {
      const deviceToken = 'push-device-token';
      final expectedMatrixDeviceId = md5
          .convert(utf8.encode(deviceToken))
          .toString();

      when(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: any(named: 'token'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => matrix.LoginResponse(
          accessToken: 'token',
          deviceId: expectedMatrixDeviceId,
          userId: '@alice:example.com',
        ),
      );

      final userId = await service.ensureLoggedIn(
        did: 'did:test:alice',
        deviceId: deviceToken,
      );

      expect(userId, '@alice:example.com');
      verify(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: matrixCredentialJwt,
          deviceId: expectedMatrixDeviceId,
        ),
      ).called(1);
    });

    test(
      'does not re-login when already logged in as expected user/device',
      () async {
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();
        final expectedLocalpart = md5
            .convert(utf8.encode('did:test:alice'))
            .toString();

        when(() => matrixClient.accessToken).thenReturn('token');
        when(
          () => matrixClient.userID,
        ).thenReturn('@$expectedLocalpart:example.com');
        when(() => matrixClient.deviceID).thenReturn(expectedMatrixDeviceId);
        when(() => matrixClient.encryptionEnabled).thenReturn(true);

        final userId = await service.ensureLoggedIn(
          did: 'did:test:alice',
          deviceId: deviceToken,
        );

        expect(userId, '@$expectedLocalpart:example.com');
        verifyNever(
          () => matrixClient.login(
            didAuthLoginType,
            identifier: any(named: 'identifier'),
            token: any(named: 'token'),
            deviceId: any(named: 'deviceId'),
          ),
        );
      },
    );

    test('re-logins when logged in as a different user', () async {
      const deviceToken = 'push-device-token';
      final expectedMatrixDeviceId = md5
          .convert(utf8.encode(deviceToken))
          .toString();

      when(() => matrixClient.accessToken).thenReturn('token');
      when(() => matrixClient.userID).thenReturn('@bob:example.com');
      when(() => matrixClient.deviceID).thenReturn(expectedMatrixDeviceId);

      when(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: any(named: 'token'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => matrix.LoginResponse(
          accessToken: 'token',
          deviceId: expectedMatrixDeviceId,
          userId: '@alice:example.com',
        ),
      );

      final userId = await service.ensureLoggedIn(
        did: 'did:test:alice',
        deviceId: deviceToken,
      );

      expect(userId, '@alice:example.com');
      verify(
        () => matrixClient.login(
          didAuthLoginType,
          identifier: any(named: 'identifier'),
          token: matrixCredentialJwt,
          deviceId: expectedMatrixDeviceId,
        ),
      ).called(1);
    });
  });
}
