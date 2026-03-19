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

    setUp(() {
      matrixClient = MockMatrixClient();
      room = MockMatrixRoom();
      service = MatrixService(matrixClient: matrixClient);
      when(() => matrixClient.accessToken).thenReturn(null);
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

        final userId = await service.login(
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
      },
    );

    test('createRoomForGroup creates an encrypted group chat', () async {
      when(() => matrixClient.encryptionEnabled).thenReturn(true);
      when(
        () => matrixClient.createGroupChat(
          enableEncryption: true,
          waitForSync: true,
        ),
      ).thenAnswer((_) async => '!room:example.com');

      final roomId = await service.createRoomForGroup();

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

      expect(service.createRoomForGroup(), throwsA(isA<StateError>()));
    });

    test(
      'sendMessage uses room API so encrypted rooms are handled by matrix',
      () async {
        when(() => matrixClient.encryptionEnabled).thenReturn(true);
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
  });
}
