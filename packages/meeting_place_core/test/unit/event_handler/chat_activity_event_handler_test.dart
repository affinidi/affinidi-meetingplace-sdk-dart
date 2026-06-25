import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ChannelActivityType, ContactCard;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/chat_activity_event_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

const _permanentChannelDid = 'did:key:permanent-channel';
const _channelDid = 'did:key:channel';
const _mediatorDid = 'did:web:mediator';
const _testRoomId = '!room123:matrix.example.com';

Channel _matrixChannel({String? matrixSyncMarker, int seqNo = 0}) {
  return Channel(
    offerLink: 'offer-link',
    publishOfferDid: _channelDid,
    mediatorDid: _mediatorDid,
    status: ChannelStatus.inaugurated,
    isConnectionInitiator: true,
    contactCard: ContactCard(
      did: 'did:key:other-party',
      type: 'individual',
      contactInfo: const {'fullName': 'Alice'},
    ),
    type: ChannelType.individual,
    transport: ChannelTransport.matrix,
    permanentChannelDid: _permanentChannelDid,
    matrixSyncMarker: matrixSyncMarker,
    seqNo: seqNo,
  );
}

MatrixRoomEvent _inboundMessage({
  required String id,
  Map<String, dynamic>? content,
}) {
  return MatrixRoomEvent(
    id: id,
    type: 'm.room.message',
    userId: '@sender:matrix.example.com',
    roomId: _testRoomId,
    content: content ?? const {'msgtype': 'm.text', 'body': 'hello'},
    timestamp: DateTime.now().toUtc(),
    isFromMe: false,
  );
}

MatrixRoomEvent _outboundMessage({required String id}) {
  return MatrixRoomEvent(
    id: id,
    type: 'm.room.message',
    userId: '@me:matrix.example.com',
    roomId: _testRoomId,
    content: const {'msgtype': 'm.text', 'body': 'hi'},
    timestamp: DateTime.now().toUtc(),
    isFromMe: true,
  );
}

MatrixRoomEvent _editMessage({required String id, required String replacesId}) {
  return MatrixRoomEvent(
    id: id,
    type: 'm.room.message',
    userId: '@sender:matrix.example.com',
    roomId: _testRoomId,
    content: {
      'msgtype': 'm.text',
      'body': 'edited',
      'm.relates_to': {'rel_type': 'm.replace', 'event_id': replacesId},
    },
    timestamp: DateTime.now().toUtc(),
    isFromMe: false,
  );
}

void main() {
  late ChatActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockWallet mockWallet;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockMatrixService mockMatrixService;
  late MockDidManager mockDidManager;
  late MockMediatorService mockMediatorService;

  final channelActivity = ChannelActivity(
    id: const Uuid().v4(),
    did: _channelDid,
    type: ChannelActivityType.vdipRequestIssuance,
  );

  setUpAll(() {
    registerFallbackValue(
      Channel(
        offerLink: 'fallback',
        publishOfferDid: 'did:key:fallback',
        mediatorDid: 'did:web:fallback',
        status: ChannelStatus.inaugurated,
        isConnectionInitiator: false,
        contactCard: ContactCard(
          did: 'did:key:fallback-other',
          type: 'individual',
          contactInfo: const {},
        ),
        type: ChannelType.individual,
      ),
    );
    registerFallbackValue(MockDidManager(did: 'did:key:fallback'));
  });

  setUp(() {
    mockLogger = MockLogger();
    mockWallet = MockWallet();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockConnectionOfferRepository = MockConnectionOfferRepository();
    mockMatrixService = MockMatrixService();
    mockMediatorService = MockMediatorService();
    mockDidManager = MockDidManager(did: _permanentChannelDid);

    when(
      () => mockLogger.info(any(), name: any(named: 'name')),
    ).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        name: any(named: 'name'),
      ),
    ).thenReturn(null);

    handler = ChatActivityEventHandler(
      wallet: mockWallet,
      mediatorService: mockMediatorService,
      connectionManager: mockConnectionManager,
      connectionOfferRepository: mockConnectionOfferRepository,
      channelService: mockChannelService,
      matrixService: mockMatrixService,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: mockLogger,
    );

    when(
      () => mockConnectionManager.getDidManagerForDid(
        mockWallet,
        _permanentChannelDid,
      ),
    ).thenAnswer((_) async => mockDidManager);

    when(
      () => mockMatrixService.resolveRoomIdForChannel(
        didManager: any(named: 'didManager'),
        channel: any(named: 'channel'),
      ),
    ).thenAnswer((_) async => _testRoomId);

    when(
      () => mockChannelService.updateMatrixSyncMarker(any(), any()),
    ).thenAnswer((_) async {});
  });

  group('ChatActivityEventHandler._syncFromMatrixRoom', () {
    test(
      'bumps seqNo and updates sync marker for inbound new messages',
      () async {
        final channel = _matrixChannel(matrixSyncMarker: r'$prev');
        final events = [
          _inboundMessage(id: r'$evt1'),
          _inboundMessage(id: r'$evt2'),
        ];

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchRoomHistory(
            any(),
            didManager: any(named: 'didManager'),
            sinceEventId: any(named: 'sinceEventId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(2));
        verify(
          () => mockChannelService.updateMatrixSyncMarker(channel, r'$evt2'),
        ).called(1);
      },
    );

    test(
      'passes channel matrixSyncMarker as sinceEventId to fetchRoomHistory',
      () async {
        const marker = r'$stored-marker';
        final channel = _matrixChannel(matrixSyncMarker: marker);

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchRoomHistory(
            any(),
            didManager: any(named: 'didManager'),
            sinceEventId: any(named: 'sinceEventId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await handler.process(channelActivity);

        final verification = verify(
          () => mockMatrixService.fetchRoomHistory(
            _testRoomId,
            didManager: any(named: 'didManager'),
            sinceEventId: captureAny(named: 'sinceEventId'),
            limit: any(named: 'limit'),
          ),
        )..called(1);
        expect(verification.captured.single, equals(marker));
      },
    );

    test(
      'returns early without updating marker when no events are fetched',
      () async {
        final channel = _matrixChannel(matrixSyncMarker: r'$prev');

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchRoomHistory(
            any(),
            didManager: any(named: 'didManager'),
            sinceEventId: any(named: 'sinceEventId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(0));
        verifyNever(
          () => mockChannelService.updateMatrixSyncMarker(any(), any()),
        );
      },
    );

    test(
      'does not bump seqNo for outbound messages (isFromMe = true)',
      () async {
        final channel = _matrixChannel();
        final events = [
          _outboundMessage(id: r'$evt1'),
          _outboundMessage(id: r'$evt2'),
        ];

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchRoomHistory(
            any(),
            didManager: any(named: 'didManager'),
            sinceEventId: any(named: 'sinceEventId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(0));
        verify(
          () => mockChannelService.updateMatrixSyncMarker(channel, r'$evt2'),
        ).called(1);
      },
    );

    test(
      'does not bump seqNo for edit events (m.relates_to: m.replace)',
      () async {
        final channel = _matrixChannel();
        final events = [_editMessage(id: r'$edit1', replacesId: r'$original')];

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchRoomHistory(
            any(),
            didManager: any(named: 'didManager'),
            sinceEventId: any(named: 'sinceEventId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(0));
        verify(
          () => mockChannelService.updateMatrixSyncMarker(channel, r'$edit1'),
        ).called(1);
      },
    );

    test('updates sync marker to last event id (not first)', () async {
      final channel = _matrixChannel();
      final events = [
        _inboundMessage(id: r'$evt-first'),
        _inboundMessage(id: r'$evt-middle'),
        _inboundMessage(id: r'$evt-last'),
      ];

      when(
        () => mockChannelService.findChannelByDid(_channelDid),
      ).thenAnswer((_) async => channel);
      when(
        () => mockMatrixService.fetchRoomHistory(
          any(),
          didManager: any(named: 'didManager'),
          sinceEventId: any(named: 'sinceEventId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => events);

      await handler.process(channelActivity);

      verify(
        () => mockChannelService.updateMatrixSyncMarker(channel, r'$evt-last'),
      ).called(1);
      verifyNever(
        () => mockChannelService.updateMatrixSyncMarker(channel, r'$evt-first'),
      );
    });
  });
}
