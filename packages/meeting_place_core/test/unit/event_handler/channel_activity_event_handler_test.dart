import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/event_handler/exceptions/event_handler_exception.dart';
import 'package:meeting_place_core/src/meeting_place_core_sdk_error_code.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/service/mediator/fetch_messages_options.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_message.dart';
import 'package:meeting_place_core/src/vdip/channel_activity_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

void main() {
  late ChannelActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockWallet mockWallet;
  late MockMediatorService mockMediatorService;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockDidManager mockDidManager;
  late MockVdipClient mockVdipClient;

  const permanentChannelDid = 'did:key:permanent-channel';
  const channelDid = 'did:key:channel';
  const mediatorDid = 'did:web:mediator';
  const messageHash = 'hash-123';

  final channel = Channel(
    offerLink: 'offer-link',
    publishOfferDid: channelDid,
    mediatorDid: mediatorDid,
    status: ChannelStatus.inaugurated,
    isConnectionInitiator: true,
    contactCard: ContactCard(
      did: 'did:key:other-party',
      type: 'individual',
      contactInfo: const {'fullName': 'Alice'},
    ),
    type: ChannelType.individual,
    permanentChannelDid: permanentChannelDid,
  );

  final event = ChannelActivity(
    id: const Uuid().v4(),
    did: channelDid,
    type: ChannelActivityType.vdipRequestIssuance,
  );

  final otherVdipEvent = ChannelActivity(
    id: const Uuid().v4(),
    did: channelDid,
    type: ChannelActivityType.vdipIssuedCredentials,
  );

  setUpAll(() {
    registerFallbackValue(const FetchMessagesOptions());
    registerFallbackValue(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/fallback'),
        body: {},
      ),
    );
  });

  setUp(() {
    mockLogger = MockLogger();
    mockWallet = MockWallet();
    mockMediatorService = MockMediatorService();
    mockConnectionOfferRepository = MockConnectionOfferRepository();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockDidManager = MockDidManager(did: permanentChannelDid);
    mockVdipClient = MockVdipClient();

    when(
      () => mockLogger.info(any(), name: any(named: 'name')),
    ).thenReturn(null);
    when(
      () => mockLogger.warning(any(), name: any(named: 'name')),
    ).thenReturn(null);

    handler = ChannelActivityEventHandler(
      wallet: mockWallet,
      mediatorService: mockMediatorService,
      connectionManager: mockConnectionManager,
      channelService: mockChannelService,
      connectionOfferRepository: mockConnectionOfferRepository,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: mockLogger,
      vdipClient: mockVdipClient,
    );

    when(
      () => mockChannelService.findChannelByDid(channelDid),
    ).thenAnswer((_) async => channel);

    when(
      () => mockConnectionManager.getDidManagerForDid(
        mockWallet,
        permanentChannelDid,
      ),
    ).thenAnswer((_) async => mockDidManager);

    when(
      () => mockMediatorService.deleteMessages(
        didManager: mockDidManager,
        mediatorDid: mediatorDid,
        messageHashes: [messageHash],
      ),
    ).thenAnswer((_) async {});

    when(() => mockVdipClient.dispatch(any())).thenReturn(null);
  });

  group('ChannelActivityEventHandler', () {
    test('dedupe treats different activity types on same DID as distinct', () {
      final processedEvents = [
        DiscoveryEvent<ChannelActivity>(
          id: const Uuid().v4(),
          type: ControlPlaneEventType.ChannelActivity,
          data: event,
          status: DiscoveryEventStatus.New,
        ),
      ];

      expect(
        handler.hasChannelActivityBeenProcessed(event, processedEvents),
        isTrue,
      );
      expect(
        handler.hasChannelActivityBeenProcessed(
          otherVdipEvent,
          processedEvents,
        ),
        isFalse,
      );
    });

    test('fetches, dispatches, and deletes VDIP messages', () async {
      final mediatorMessage = MediatorMessage(
        plainTextMessage: PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipRequestIssuanceMessage.messageType,
          body: {},
        ),
        messageHash: messageHash,
      );

      when(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => [mediatorMessage]);

      final result = await handler.process(event);

      expect(result, isEmpty);

      final verification = verify(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          options: captureAny(named: 'options'),
        ),
      )..called(1);

      final options = verification.captured.single as FetchMessagesOptions;
      expect(
        options.filterByMessageTypes,
        equals([
          VdipRequestIssuanceMessage.messageType.toString(),
          VdipIssuedCredentialMessage.messageType.toString(),
        ]),
      );
      expect(options.deleteOnRetrieve, isFalse);

      verify(
        () => mockVdipClient.dispatch(mediatorMessage.plainTextMessage),
      ).called(1);
      verify(
        () => mockMediatorService.deleteMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          messageHashes: [messageHash],
        ),
      ).called(1);
    });

    test('throws domain exception when channel lacks permanent DID', () async {
      final channelWithoutPermanentDid = Channel(
        offerLink: 'offer-link',
        publishOfferDid: channelDid,
        mediatorDid: mediatorDid,
        status: ChannelStatus.inaugurated,
        isConnectionInitiator: true,
        contactCard: ContactCard(
          did: 'did:key:other-party',
          type: 'individual',
          contactInfo: const {'fullName': 'Alice'},
        ),
        type: ChannelType.individual,
      );

      when(
        () => mockChannelService.findChannelByDid(channelDid),
      ).thenAnswer((_) async => channelWithoutPermanentDid);

      expect(
        handler.process(event),
        throwsA(
          isA<EventHandlerException>().having(
            (error) => error.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.channelMissingPermanentChannelDid,
          ),
        ),
      );
    });

    test(
      'logs warning and skips deletion when message hash is missing',
      () async {
        final mediatorMessage = MediatorMessage(
          plainTextMessage: PlainTextMessage(
            id: const Uuid().v4(),
            type: VdipRequestIssuanceMessage.messageType,
            body: {},
          ),
        );

        when(
          () => mockMediatorService.fetchMessages(
            didManager: mockDidManager,
            mediatorDid: mediatorDid,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => [mediatorMessage]);

        final result = await handler.process(event);

        expect(result, isEmpty);
        verify(
          () => mockVdipClient.dispatch(mediatorMessage.plainTextMessage),
        ).called(1);
        verifyNever(
          () => mockMediatorService.deleteMessages(
            didManager: mockDidManager,
            mediatorDid: mediatorDid,
            messageHashes: [messageHash],
          ),
        );
        verify(
          () => mockLogger.warning(
            'Skipping VDIP mediator message deletion because message hash is '
            'missing',
            name: 'ChannelActivityEventHandler',
          ),
        ).called(1);
      },
    );
  });
}
