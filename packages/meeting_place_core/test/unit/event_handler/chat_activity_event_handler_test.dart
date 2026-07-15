import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/chat_activity_event_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

const _permanentChannelDid = 'did:key:permanent-channel';
const _channelDid = 'did:key:channel';
const _mediatorDid = 'did:web:mediator';

Channel _matrixChannel({String? messageSyncMarker, int seqNo = 0}) {
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
    messageSyncMarker: messageSyncMarker,
    seqNo: seqNo,
  );
}

TransportEvent _inboundMessage({
  required String id,
  Map<String, dynamic>? content,
  DateTime? timestamp,
}) {
  return TransportEvent(
    id: id,
    type: 'm.room.message',
    senderDid: 'did:test:sender',
    channelId: _permanentChannelDid,
    content: content ?? const {'msgtype': 'm.text', 'body': 'hello'},
    timestamp: timestamp ?? DateTime.now().toUtc(),
    isFromMe: false,
    metadata: const {'sender_id': '@sender:matrix.local'},
  );
}

TransportEvent _outboundMessage({required String id, DateTime? timestamp}) {
  return TransportEvent(
    id: id,
    type: 'm.room.message',
    senderDid: 'did:test:me',
    channelId: _permanentChannelDid,
    content: const {'msgtype': 'm.text', 'body': 'hi'},
    timestamp: timestamp ?? DateTime.now().toUtc(),
    isFromMe: true,
    metadata: const {'sender_id': '@me:matrix.local'},
  );
}

TransportEvent _editMessage({required String id, required String replacesId}) {
  return TransportEvent(
    id: id,
    type: 'm.room.message',
    senderDid: 'did:test:sender',
    channelId: _permanentChannelDid,
    content: {
      'msgtype': 'm.text',
      'body': 'edited',
      'm.relates_to': {'rel_type': 'm.replace', 'event_id': replacesId},
    },
    timestamp: DateTime.now().toUtc(),
    isFromMe: false,
    metadata: const {'sender_id': '@sender:matrix.local'},
  );
}

void main() {
  late ChatActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockWallet mockWallet;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockMeetingPlaceTransport mockMatrixService;
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
    registerFallbackValue(
      TransportEvent(
        id: 'fallback',
        type: 'm.room.message',
        content: const {},
        channelId: 'fallback',
        timestamp: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockLogger = MockLogger();
    mockWallet = MockWallet();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockConnectionOfferRepository = MockConnectionOfferRepository();
    mockMatrixService = MockMeetingPlaceTransport();
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
      channelTransport: mockMatrixService,
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
      () => mockChannelService.updateMessageSyncMarker(any(), any()),
    ).thenAnswer((_) async {});

    when(() => mockMatrixService.isNewInboundMessage(any())).thenAnswer((inv) {
      final event = inv.positionalArguments.first as TransportEvent;
      final isEdit =
          (event.content['m.relates_to'] as Map?)?['rel_type'] == 'm.replace';
      return !event.isFromMe && !isEdit;
    });
  });

  group('ChatActivityEventHandler._syncFromMatrixRoom', () {
    test(
      'bumps seqNo and updates sync marker for inbound new messages',
      () async {
        final channel = _matrixChannel(messageSyncMarker: r'$prev');
        final events = [
          _inboundMessage(
            id: r'$evt1',
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
          ),
          _inboundMessage(
            id: r'$evt2',
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, 2),
          ),
        ];

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchHistory(
            channel: any(named: 'channel'),
            didManager: any(named: 'didManager'),
            since: any(named: 'since'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(2));
        verify(
          () => mockChannelService.updateMessageSyncMarker(channel, r'$evt2'),
        ).called(1);
      },
    );

    test('passes channel messageSyncMarker as since to fetchHistory', () async {
      const marker = r'$stored-marker';
      final channel = _matrixChannel(messageSyncMarker: marker);

      when(
        () => mockChannelService.findChannelByDid(_channelDid),
      ).thenAnswer((_) async => channel);
      when(
        () => mockMatrixService.fetchHistory(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
          since: any(named: 'since'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      await handler.process(channelActivity);

      final verification = verify(
        () => mockMatrixService.fetchHistory(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
          since: captureAny(named: 'since'),
          limit: any(named: 'limit'),
        ),
      )..called(1);
      expect(verification.captured.single, equals(marker));
    });

    test(
      'returns early without updating marker when no events are fetched',
      () async {
        final channel = _matrixChannel(messageSyncMarker: r'$prev');

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchHistory(
            channel: any(named: 'channel'),
            didManager: any(named: 'didManager'),
            since: any(named: 'since'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(0));
        verifyNever(
          () => mockChannelService.updateMessageSyncMarker(any(), any()),
        );
      },
    );

    test(
      'does not bump seqNo for outbound messages (isFromMe = true)',
      () async {
        final channel = _matrixChannel();
        final events = [
          _outboundMessage(
            id: r'$evt1',
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
          ),
          _outboundMessage(
            id: r'$evt2',
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, 2),
          ),
        ];

        when(
          () => mockChannelService.findChannelByDid(_channelDid),
        ).thenAnswer((_) async => channel);
        when(
          () => mockMatrixService.fetchHistory(
            channel: any(named: 'channel'),
            didManager: any(named: 'didManager'),
            since: any(named: 'since'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(0));
        verify(
          () => mockChannelService.updateMessageSyncMarker(channel, r'$evt2'),
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
          () => mockMatrixService.fetchHistory(
            channel: any(named: 'channel'),
            didManager: any(named: 'didManager'),
            since: any(named: 'since'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await handler.process(channelActivity);

        expect(channel.seqNo, equals(0));
        verify(
          () => mockChannelService.updateMessageSyncMarker(channel, r'$edit1'),
        ).called(1);
      },
    );

    test('advances sync marker to the newest event by timestamp regardless of '
        'list position (matrix history is newest-first)', () async {
      final channel = _matrixChannel();
      // Matrix `fetchHistory` returns events newest-first, so the newest
      // event is at the head and the oldest at the tail. Anchoring the marker
      // by list position (events.last) would regress it to the oldest event
      // and cause the next sync to re-count the window, inflating seqNo.
      final events = [
        _inboundMessage(
          id: r'$evt-newest',
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, 3),
        ),
        _inboundMessage(
          id: r'$evt-middle',
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, 2),
        ),
        _inboundMessage(
          id: r'$evt-oldest',
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
        ),
      ];

      when(
        () => mockChannelService.findChannelByDid(_channelDid),
      ).thenAnswer((_) async => channel);
      when(
        () => mockMatrixService.fetchHistory(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
          since: any(named: 'since'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => events);

      await handler.process(channelActivity);

      verify(
        () =>
            mockChannelService.updateMessageSyncMarker(channel, r'$evt-newest'),
      ).called(1);
      verifyNever(
        () =>
            mockChannelService.updateMessageSyncMarker(channel, r'$evt-oldest'),
      );
    });
  });
}
