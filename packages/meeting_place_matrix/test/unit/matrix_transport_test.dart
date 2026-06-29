import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart'
    show
        Channel,
        ChannelStatus,
        ChannelTransport,
        ChannelType,
        ContactCard;
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockMatrixService extends Mock implements MatrixService {}

class _MockDidManager extends Mock implements DidManager {}

class _FakeChannel extends Fake implements Channel {}

Channel _matrixChannel() => Channel(
  offerLink: 'offer',
  publishOfferDid: 'pubDid',
  mediatorDid: 'medDid',
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(did: 'did:test:alice', type: 'individual', contactInfo: const {}),
  type: ChannelType.individual,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: true,
  permanentChannelDid: 'did:test:alice',
  otherPartyPermanentChannelDid: 'did:test:bob',
);

void main() {
  late _MockMatrixService matrixService;
  late _MockDidManager didManager;
  late MatrixTransport transport;

  setUpAll(() {
    registerFallbackValue(_MockDidManager());
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    matrixService = _MockMatrixService();
    didManager = _MockDidManager();
    transport = MatrixTransport(matrixService: matrixService);
  });

  group('sendFile', () {
    test('throws MatrixMediaException.tooLarge when bytes exceed server limit',
        () async {
      when(
        () => matrixService.getMediaConfig(didManager: any(named: 'didManager')),
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
    });

    test('uploads when bytes are within server limit', () async {
      when(
        () => matrixService.getMediaConfig(didManager: any(named: 'didManager')),
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
        () => matrixService.getMediaConfig(didManager: any(named: 'didManager')),
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
