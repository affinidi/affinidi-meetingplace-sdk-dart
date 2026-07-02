import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_type.dart';
import 'package:meeting_place_core/src/event_handler/exceptions/event_handler_exception.dart';
import 'package:meeting_place_core/src/event_handler/vdip_activity_event_handler.dart';
import 'package:meeting_place_core/src/meeting_place_core_sdk_error_code.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/service/mediator/fetch_messages_options.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

void main() {
  late VdipActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockWallet mockWallet;
  late MockMediatorService mockMediatorService;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockDidManager mockDidManager;

  const permanentChannelDid = 'did:key:permanent-channel';
  const channelDid = 'did:key:channel';
  const mediatorDid = 'did:web:mediator';

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

  setUpAll(() {
    registerFallbackValue(const FetchMessagesOptions());
    registerFallbackValue(MockDidManager(did: 'did:key:fallback-did-manager'));
    registerFallbackValue(<String>[]);
    registerFallbackValue(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/fallback'),
        body: {},
      ),
    );
    registerFallbackValue(
      Channel(
        offerLink: 'fallback-offer',
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
  });

  setUp(() {
    mockLogger = MockLogger();
    mockWallet = MockWallet();
    mockMediatorService = MockMediatorService();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockDidManager = MockDidManager(did: permanentChannelDid);

    when(
      () => mockLogger.info(any(), name: any(named: 'name')),
    ).thenReturn(null);

    handler = VdipActivityEventHandler(
      wallet: mockWallet,
      mediatorService: mockMediatorService,
      channelService: mockChannelService,
      connectionManager: mockConnectionManager,
      logger: mockLogger,
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
      () => mockChannelService.updateChannelSequence(
        any(),
        sequenceNumber: any(named: 'sequenceNumber'),
        messageSyncMarker: any(named: 'messageSyncMarker'),
      ),
    ).thenAnswer((_) async {});
  });

  group('VdipActivityEventHandler', () {
    test('advances seqNo and marker from fetched messages without dispatching '
        'or deleting', () async {
      final createdTime = DateTime.utc(2026, 6, 18, 12);
      final mediatorMessage = MediatorMessage(
        plainTextMessage: PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          body: {},
          createdTime: createdTime,
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

      expect(result, [channel]);

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
      expect(options.startFrom, channel.messageSyncMarker);

      verify(
        () => mockChannelService.updateChannelSequence(
          channel,
          sequenceNumber: channel.seqNo + 1,
          messageSyncMarker: createdTime,
        ),
      ).called(1);

      verifyNever(
        () => mockMediatorService.deleteMessages(
          didManager: any(named: 'didManager'),
          mediatorDid: any(named: 'mediatorDid'),
          messageHashes: any(named: 'messageHashes'),
        ),
      );
    });

    test('does not update sequence when no new messages are fetched', () async {
      when(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => []);

      final result = await handler.process(event);

      expect(result, [channel]);
      verifyNever(
        () => mockChannelService.updateChannelSequence(
          any(),
          sequenceNumber: any(named: 'sequenceNumber'),
          messageSyncMarker: any(named: 'messageSyncMarker'),
        ),
      );
    });

    test('does not update sequence when message has no createdTime', () async {
      final mediatorMessage = MediatorMessage(
        plainTextMessage: PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
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

      await handler.process(event);

      verifyNever(
        () => mockChannelService.updateChannelSequence(
          any(),
          sequenceNumber: any(named: 'sequenceNumber'),
          messageSyncMarker: any(named: 'messageSyncMarker'),
        ),
      );
    });

    test(
      '''does not count a message whose createdTime does not exceed existing marker''',
      () async {
        final existingMarker = DateTime.utc(2026, 6, 18, 12);
        final channelWithMarker = Channel(
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
        )..messageSyncMarker = existingMarker;

        when(
          () => mockChannelService.findChannelByDid(channelDid),
        ).thenAnswer((_) async => channelWithMarker);

        when(
          () => mockMediatorService.fetchMessages(
            didManager: mockDidManager,
            mediatorDid: mediatorDid,
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => [
            MediatorMessage(
              plainTextMessage: PlainTextMessage(
                id: const Uuid().v4(),
                type: VdipIssuedCredentialMessage.messageType,
                body: {},
                createdTime: DateTime.utc(2026, 6, 18, 11),
              ),
            ),
          ],
        );

        await handler.process(event);

        verifyNever(
          () => mockChannelService.updateChannelSequence(
            any(),
            sequenceNumber: any(named: 'sequenceNumber'),
            messageSyncMarker: any(named: 'messageSyncMarker'),
          ),
        );
      },
    );

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
  });
}
