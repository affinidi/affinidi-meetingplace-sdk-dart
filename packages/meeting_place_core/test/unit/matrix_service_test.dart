import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/src/service/matrix/matrix_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMatrixClient extends Mock implements matrix.Client {}

class MockMatrixRoom extends Mock implements matrix.Room {}

void main() {
  group('MatrixService', () {
    late MockMatrixClient matrixClient;
    late MockMatrixRoom room;
    late MatrixService service;

    setUpAll(() {
      registerFallbackValue(
        matrix.AuthenticationUserIdentifier(user: 'fallback-user'),
      );
    });

    setUp(() {
      matrixClient = MockMatrixClient();
      room = MockMatrixRoom();
      service = MatrixService(matrixClient: matrixClient);
      when(() => matrixClient.accessToken).thenReturn(null);
      when(() => matrixClient.userID).thenReturn(null);
      when(() => matrixClient.deviceID).thenReturn(null);
      when(() => matrixClient.encryptionEnabled).thenReturn(false);
    });

    test(
      'register hashes the device token before using it as Matrix deviceId',
      () async {
        const deviceToken = 'push-device-token';
        final expectedMatrixDeviceId = md5
            .convert(utf8.encode(deviceToken))
            .toString();

        when(
          () => matrixClient.register(
            username: any(named: 'username'),
            password: any(named: 'password'),
            deviceId: any(named: 'deviceId'),
            initialDeviceDisplayName: any(named: 'initialDeviceDisplayName'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => matrix.RegisterResponse(
            accessToken: 'token',
            deviceId: expectedMatrixDeviceId,
            userId: '@alice:example.com',
          ),
        );

        final userId = await service.register(
          permanentChannelDid: 'did:test:alice',
          deviceId: deviceToken,
        );

        expect(userId, '@alice:example.com');
        verify(
          () => matrixClient.register(
            username: any(named: 'username'),
            password: any(named: 'password'),
            deviceId: expectedMatrixDeviceId,
            initialDeviceDisplayName: 'did:test:alice',
            auth: any(named: 'auth'),
          ),
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
            matrix.LoginType.mLoginPassword,
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
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
            matrix.LoginType.mLoginPassword,
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
            deviceId: expectedMatrixDeviceId,
          ),
        ).called(1);
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
      when(() => matrixClient.encryptionEnabled).thenReturn(false);

      expect(
        service.createRoomForGroup(
          did: 'did:test:alice',
          deviceId: 'push-device-token',
        ),
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
            addMentions: false,
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
            addMentions: false,
          ),
        ).called(1);
      },
    );

    test(
      'sendImageByMxcUri sends m.image with url referencing the provided mxc URI',
      () async {
        when(() => matrixClient.encryptionEnabled).thenReturn(true);
        when(
          () => matrixClient.getRoomById('!room:example.com'),
        ).thenReturn(room);

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

        final eventId = await service.sendImageByMxcUri(
          roomId: '!room:example.com',
          mxcUri: 'mxc://localhost:9000/FkQfmXCmuDlXmYDKPuvWsCrg',
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
  });

  group('MatrixService.ensureLoggedIn', () {
    late MockMatrixClient matrixClient;
    late MatrixService service;

    setUp(() {
      matrixClient = MockMatrixClient();
      service = MatrixService(matrixClient: matrixClient);
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
          matrix.LoginType.mLoginPassword,
          user: any(named: 'user'),
          password: any(named: 'password'),
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
          matrix.LoginType.mLoginPassword,
          user: any(named: 'user'),
          password: any(named: 'password'),
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

        final userId = await service.ensureLoggedIn(
          did: 'did:test:alice',
          deviceId: deviceToken,
        );

        expect(userId, '@$expectedLocalpart:example.com');
        verifyNever(
          () => matrixClient.login(
            matrix.LoginType.mLoginPassword,
            user: any(named: 'user'),
            password: any(named: 'password'),
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
          matrix.LoginType.mLoginPassword,
          user: any(named: 'user'),
          password: any(named: 'password'),
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
          matrix.LoginType.mLoginPassword,
          user: any(named: 'user'),
          password: any(named: 'password'),
          deviceId: expectedMatrixDeviceId,
        ),
      ).called(1);
    });
  });
}
