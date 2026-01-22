import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/loggers/default_meeting_place_core_sdk_logger.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/mediator/fetch_messages_options.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:meeting_place_core/src/event_handler/invitation_accepted_event_handler.dart';
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/entity/connection_offer.dart';
import 'package:meeting_place_core/src/protocol/meeting_place_protocol.dart';
import 'package:meeting_place_core/src/repository/connection_offer_repository.dart';
import 'package:meeting_place_core/src/repository/channel_repository.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

void main() {
  late InvitationAcceptedEventHandler handler;
  late MockWallet mockWallet;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockChannelRepository mockChannelRepository;
  late MockConnectionManager mockConnectionManager;
  late MockMediatorService mockMediatorService;
  late MockDidManager mockDidManager;

  final mediatorDid = 'did:web:mediator-did';

  final fetchMessageOptions = FetchMessagesOptions(
    filterByMessageTypes: [MeetingPlaceProtocol.invitationAcceptance.value],
  );

  final offerLink = Uuid().v4();
  final publishOfferDid = 'did:key:publisher-did';
  final acceptOfferDid = 'did:key:accept-did';
  final messageHash = 'hash-123';

  final connectionOffer = ConnectionOffer(
    offerName: 'Sample offer',
    offerLink: offerLink,
    mnemonic: 'sample-mnemonic',
    oobInvitationMessage: '',
    status: ConnectionOfferStatus.published,
    publishOfferDid: publishOfferDid,
    mediatorDid: mediatorDid,
    type: ConnectionOfferType.meetingPlaceInvitation,
    contactCard: ContactCard(
      did: 'did:key:contact-card-did',
      type: 'individual',
      contactInfo: const {'fullName': 'Test User'},
    ),
    ownedByMe: true,
    createdAt: DateTime.now().toUtc(),
  );

  final event = cp.InvitationAccept(
    id: Uuid().v4(),
    acceptOfferAsDid: acceptOfferDid,
    offerLink: offerLink,
  );

  final channel = Channel(
    offerLink: offerLink,
    publishOfferDid: publishOfferDid,
    mediatorDid: mediatorDid,
    status: ChannelStatus.approved,
    contactCard: ContactCard(
      did: 'did:key:contact-card-did',
      type: 'individual',
      contactInfo: const {'fullName': 'Test User'},
    ),
    type: ChannelType.individual,
  );

  setUpAll(() {
    mockWallet = MockWallet();
    mockConnectionOfferRepository = MockConnectionOfferRepository();
    mockChannelRepository = MockChannelRepository();
    mockConnectionManager = MockConnectionManager();
    mockMediatorService = MockMediatorService();
    mockDidManager = MockDidManager(did: publishOfferDid);

    handler = InvitationAcceptedEventHandler(
      wallet: mockWallet,
      connectionOfferRepository: mockConnectionOfferRepository,
      channelRepository: mockChannelRepository,
      connectionManager: mockConnectionManager,
      mediatorService: mockMediatorService,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: DefaultMeetingPlaceCoreSDKLogger(),
    );

    registerFallbackValue(fetchMessageOptions);
    registerFallbackValue(channel);

    when(
      () => mockConnectionOfferRepository.getConnectionOfferByOfferLink(
        offerLink,
      ),
    ).thenAnswer((_) async => connectionOffer);

    when(
      () => mockConnectionManager.getDidManagerForDid(
        mockWallet,
        publishOfferDid,
      ),
    ).thenAnswer((_) async => mockDidManager);

    when(
      () => mockChannelRepository.createChannel(any()),
    ).thenAnswer((_) async => {});

    when(
      () => mockMediatorService.deletedMessages(
        didManager: mockDidManager,
        mediatorDid: mediatorDid,
        messageHashes: [messageHash],
      ),
    ).thenAnswer((_) async => {});
  });

  group('retry behavior', () {
    final List<Channel> processResult = [];

    setUpAll(() async {
      // Mediator returns message on second attempt
      final fetchMessagesResponses = <List<MediatorMessage>>[
        [], // First attempt: no messages
        [
          // Second attempt: one message
          MediatorMessage(
            plainTextMessage: PlainTextMessage(
              id: Uuid().v4(),
              from: acceptOfferDid,
              to: [publishOfferDid],
              type: Uri.parse(MeetingPlaceProtocol.invitationAcceptance.value),
              body: {'channel_did': 'permanent-permanent-did'},
            ),
            messageHash: messageHash,
          ),
        ],
      ];

      when(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => fetchMessagesResponses.removeAt(0));

      processResult.addAll(await handler.process(event));
    });

    test('succeed on second attempt to fetch messages', () async {
      expect(processResult, isA<List<Channel>>());
    });

    test('fetchMessages called twice', () async {
      verify(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          options: any(named: 'options'), // Matches any instance
        ),
      ).called(2);
    });
  });

  group('retry behavior for exceeded retries', () {
    setUpAll(() {
      // Mediator returns no messages
      when(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => []);
    });

    test('respect maximum number of retries', () async {
      await handler.process(event);
      verify(
        () => mockMediatorService.fetchMessages(
          didManager: mockDidManager,
          mediatorDid: any(named: 'mediatorDid'),
          options: any(named: 'options'),
        ),
      ).called(3);
    });

    test('returns empty list', () async {
      final result = await handler.process(event);
      expect(result, isEmpty);
    });
  });
}

// Mock classes
class MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class MockChannelRepository extends Mock implements ChannelRepository {}

class MockConnectionManager extends Mock implements ConnectionManager {}
