import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart'
    show Channel, ChannelStatus, ChannelTransport, ChannelType, ContactCard;
import 'package:meeting_place_matrix/src/matrix_media_exception.dart';
import 'package:meeting_place_matrix/src/matrix_room_event.dart';
import 'package:meeting_place_matrix/src/matrix_service.dart';
import 'package:meeting_place_matrix/src/matrix_subscription_options.dart';
import 'package:meeting_place_matrix/src/matrix_transport.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockMatrixService extends Mock implements MatrixService {}

class _MockDidManager extends Mock implements DidManager {}

class _MockDidDocument extends Mock implements DidDocument {}

class _FakeChannel extends Fake implements Channel {}

Channel _matrixChannel() => Channel(
  offerLink: 'offer',
  publishOfferDid: 'pubDid',
  mediatorDid: 'medDid',
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(
    did: 'did:test:alice',
    type: 'individual',
    contactInfo: const {},
  ),
  type: ChannelType.individual,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: true,
  permanentChannelDid: 'did:test:alice',
  otherPartyPermanentChannelDid: 'did:test:bob',
);

Channel _groupMatrixChannel() => Channel(
  offerLink: 'offer',
  publishOfferDid: 'pubDid',
  mediatorDid: 'medDid',
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(
    did: 'did:test:group',
    type: 'group',
    contactInfo: const {},
  ),
  type: ChannelType.group,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: true,
  otherPartyPermanentChannelDid: 'did:test:group',
);

void main() {
  late _MockMatrixService matrixService;
  late _MockDidManager didManager;
  late MatrixTransport transport;

  setUpAll(() {
    registerFallbackValue(_MockDidManager());
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const MatrixSubscriptionOptions());
  });

  setUp(() {
    matrixService = _MockMatrixService();
    didManager = _MockDidManager();
    transport = MatrixTransport(matrixService: matrixService);
  });

  group('subscribe', () {
    late _MockDidDocument didDocument;

    const aliceDid = 'did:test:alice';
    const bobDid = 'did:test:bob';
    // Charlie is NOT in participantDids — joined after the snapshot was taken.
    const charlieUserId = '@charlie:matrix.example.com';
    const roomId = '!room:matrix.example.com';

    setUp(() {
      didDocument = _MockDidDocument();
      when(() => didDocument.id).thenReturn(aliceDid);
      when(didManager.getDidDocument).thenAnswer((_) async => didDocument);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: any(named: 'didManager'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => roomId);
      when(
        () => matrixService.homeserver,
      ).thenReturn(Uri.parse('https://matrix.example.com'));
    });

    test('m.room.member join from unknown member is yielded with Matrix userId '
        'as senderDid fallback', () async {
      final joinEvent = MatrixRoomEvent(
        id: 'evt-join',
        type: 'm.room.member',
        userId: charlieUserId,
        roomId: roomId,
        content: const {'membership': 'join'},
        timestamp: DateTime.now().toUtc().add(const Duration(seconds: 1)),
        stateKey: charlieUserId,
      );

      when(
        () => matrixService.subscribeToRoom(
          any(),
          didManager: any(named: 'didManager'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => Stream.fromIterable([joinEvent]));

      final events = await transport
          .subscribe(
            channel: _matrixChannel(),
            didManager: didManager,
            participantDids: [aliceDid, bobDid],
          )
          .toList();

      expect(events, hasLength(1));
      expect(events.first.type, 'm.room.member');
      expect(events.first.senderDid, charlieUserId);
      expect(events.first.content['membership'], 'join');
    });

    test(
      'non-membership timeline event from unknown sender is dropped',
      () async {
        final messageEvent = MatrixRoomEvent(
          id: 'evt-msg',
          type: 'm.room.message',
          userId: charlieUserId,
          roomId: roomId,
          content: const {'msgtype': 'm.text', 'body': 'hello'},
          timestamp: DateTime.now().toUtc().add(const Duration(seconds: 1)),
        );

        when(
          () => matrixService.subscribeToRoom(
            any(),
            didManager: any(named: 'didManager'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) => Stream.fromIterable([messageEvent]));

        final events = await transport
            .subscribe(
              channel: _matrixChannel(),
              didManager: didManager,
              participantDids: [aliceDid, bobDid],
            )
            .toList();

        expect(events, isEmpty);
      },
    );
  });

  group('setupChannel', () {
    test('passes group participant DIDs into createRoom inviteUsers', () async {
      when(
        () => matrixService.createRoom(
          didManager: any(named: 'didManager'),
          channelDid: any(named: 'channelDid'),
          otherPartyChannelDid: any(named: 'otherPartyChannelDid'),
          inviteUsers: any(named: 'inviteUsers'),
        ),
      ).thenAnswer((_) async => '!room:matrix.example.com');

      await transport.setupChannel(
        channel: _groupMatrixChannel(),
        didManager: didManager,
        participantDids: const [
          'did:test:member1',
          'did:test:member2',
          'did:test:member3',
        ],
      );

      verify(
        () => matrixService.createRoom(
          didManager: didManager,
          channelDid: 'did:test:group',
          otherPartyChannelDid: null,
          inviteUsers: const [
            'did:test:member1',
            'did:test:member2',
            'did:test:member3',
          ],
        ),
      ).called(1);
    });
  });

  group('sendFile', () {
    test(
      'throws MatrixMediaException.tooLarge when bytes exceed server limit',
      () async {
        when(
          () => matrixService.getMediaConfig(
            didManager: any(named: 'didManager'),
          ),
        ).thenAnswer((_) async => 8);

        await expectLater(
          () => transport.sendFile(
            channel: _matrixChannel(),
            bytes: Uint8List(64),
            contentType: 'image/png',
            didManager: didManager,
          ),
          throwsA(
            isA<MatrixMediaException>().having(
              (e) => e.code,
              'code',
              MatrixMediaException.codeTooLarge,
            ),
          ),
        );

        verifyNever(
          () => matrixService.sendFileEvent(
            any(),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
            didManager: any(named: 'didManager'),
            extraContent: any(named: 'extraContent'),
          ),
        );
      },
    );

    test('uploads when bytes are within server limit', () async {
      when(
        () =>
            matrixService.getMediaConfig(didManager: any(named: 'didManager')),
      ).thenAnswer((_) async => 1024);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: any(named: 'didManager'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => '!room:server');
      when(
        () => matrixService.sendFileEvent(
          any(),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          didManager: any(named: 'didManager'),
          extraContent: any(named: 'extraContent'),
        ),
      ).thenAnswer((_) async => '\$evt-1');

      final eventId = await transport.sendFile(
        channel: _matrixChannel(),
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
        didManager: didManager,
      );

      expect(eventId, '\$evt-1');
    });

    test('uploads when getMediaConfig returns null (no limit)', () async {
      when(
        () =>
            matrixService.getMediaConfig(didManager: any(named: 'didManager')),
      ).thenAnswer((_) async => null);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: any(named: 'didManager'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async => '!room:server');
      when(
        () => matrixService.sendFileEvent(
          any(),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          didManager: any(named: 'didManager'),
          extraContent: any(named: 'extraContent'),
        ),
      ).thenAnswer((_) async => '\$evt-1');

      final eventId = await transport.sendFile(
        channel: _matrixChannel(),
        bytes: Uint8List(9999),
        contentType: 'image/png',
        didManager: didManager,
      );

      expect(eventId, '\$evt-1');
    });
  });
}
