import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/entity/connection_offer.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/event_handler/offer_finalised_event_handler.dart';
import 'package:meeting_place_core/src/loggers/default_meeting_place_core_sdk_logger.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/protocol/meeting_place_protocol.dart';
import 'package:meeting_place_core/src/service/identity/model/permanent_identity.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'mocks/mocks.dart';

class _FakeChannel extends Fake implements Channel {}

class _FakeConnectionOffer extends Fake implements ConnectionOffer {}

class _FakeAclBody extends Fake implements AclBody {}

class _FakePlainTextMessage extends Fake implements PlainTextMessage {}

void main() {
  late OfferFinalisedEventHandler handler;
  late MockWallet mockWallet;
  late MockIdentityService mockIdentityService;
  late MockMatrixService mockMatrixService;
  late MockControlPlaneSDK mockControlPlaneSDK;
  late MockDidResolver mockDidResolver;
  late MockChannelService mockChannelService;
  late MockConnectionOfferRepository mockOfferRepo;
  late MockConnectionManager mockConnectionManager;
  late MockMediatorService mockMediatorService;
  late MockDidManager mockAcceptOfferDidManager;
  late MockDidManager mockPermanentDidManager;

  const acceptOfferDid = 'did:test:accept';
  const permanentChannelDid = 'did:test:permanent';
  const otherPartyPermanentDid = 'did:test:other-permanent';
  const mediatorDid = 'did:test:mediator';
  const offerLink = 'offer-link';
  const notificationToken = 'notification-token';

  final event = cp.OfferFinalised(
    id: 'event-id',
    offerLink: offerLink,
    notificationToken: 'other-party-notification-token',
  );

  PlainTextMessage createApprovalMessage() => PlainTextMessage(
    id: 'msg-id',
    from: 'did:test:sender',
    to: [acceptOfferDid],
    type: Uri.parse(MeetingPlaceProtocol.connectionRequestApproval.value),
    body: {'channel_did': otherPartyPermanentDid},
    parentThreadId: 'thread-id',
  );

  Channel createChannel({required ChannelTransport transport}) => Channel(
    offerLink: offerLink,
    publishOfferDid: 'did:test:publish',
    mediatorDid: mediatorDid,
    status: ChannelStatus.waitingForApproval,
    isConnectionInitiator: false,
    contactCard: ContactCard(
      did: 'did:test:card',
      type: 'individual',
      contactInfo: const {'fullName': 'Test'},
    ),
    type: ChannelType.individual,
    transport: transport,
    acceptOfferDid: acceptOfferDid,
    permanentChannelDid: permanentChannelDid,
    otherPartyPermanentChannelDid: otherPartyPermanentDid,
  );

  final connectionOffer = ConnectionOffer(
    offerName: 'Test Offer',
    offerLink: offerLink,
    mnemonic: 'mnemonic',
    oobInvitationMessage: '',
    status: ConnectionOfferStatus.published,
    publishOfferDid: 'did:test:publish',
    mediatorDid: mediatorDid,
    type: ConnectionOfferType.meetingPlaceInvitation,
    contactCard: ContactCard(
      did: 'did:test:card',
      type: 'individual',
      contactInfo: const {'fullName': 'Test'},
    ),
    ownedByMe: true,
    createdAt: DateTime.now().toUtc(),
    transport: ChannelTransport.didcomm,
  );

  setUp(() {
    mockWallet = MockWallet();
    mockIdentityService = MockIdentityService();
    mockMatrixService = MockMatrixService();
    mockControlPlaneSDK = MockControlPlaneSDK();
    mockDidResolver = MockDidResolver();
    mockChannelService = MockChannelService();
    mockOfferRepo = MockConnectionOfferRepository();
    mockConnectionManager = MockConnectionManager();
    mockMediatorService = MockMediatorService();
    mockAcceptOfferDidManager = MockDidManager(did: acceptOfferDid);
    mockPermanentDidManager = MockDidManager(did: permanentChannelDid);

    handler = OfferFinalisedEventHandler(
      wallet: mockWallet,
      connectionOfferRepository: mockOfferRepo,
      channelService: mockChannelService,
      connectionManager: mockConnectionManager,
      mediatorService: mockMediatorService,
      controlPlaneSDK: mockControlPlaneSDK,
      didResolver: mockDidResolver,
      matrixService: mockMatrixService,
      identityService: mockIdentityService,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: DefaultMeetingPlaceCoreSDKLogger(),
    );

    registerFallbackValue(_FakeChannel());
    registerFallbackValue(_FakeConnectionOffer());
    registerFallbackValue(_FakeAclBody());
    registerFallbackValue(_FakePlainTextMessage());
    registerFallbackValue(DidDocument.create(id: ''));
    registerFallbackValue(ChannelTransport.didcomm);
    registerFallbackValue(mockAcceptOfferDidManager);
    registerFallbackValue(
      cp.RegisterNotificationCommand(
        myDid: '',
        theirDid: '',
        device: cp.Device(
          deviceToken: '',
          platformType: cp.PlatformType.pushNotification,
        ),
      ),
    );
    registerFallbackValue(
      cp.NotifyChannelCommand(notificationToken: '', did: '', type: ''),
    );

    when(
      () =>
          mockConnectionManager.getDidManagerForDid(mockWallet, acceptOfferDid),
    ).thenAnswer((_) async => mockAcceptOfferDidManager);

    when(
      () => mockIdentityService.getPermanentIdentity(
        mockWallet,
        permanentChannelDid,
      ),
    ).thenAnswer(
      (_) async => PermanentIdentity(
        didManager: mockPermanentDidManager,
        didDocument: DidDocument.create(id: permanentChannelDid),
        matrixUserId: '@permanent:matrix.test',
      ),
    );

    when(() => mockControlPlaneSDK.device).thenReturn(
      cp.Device(
        deviceToken: 'token',
        platformType: cp.PlatformType.pushNotification,
      ),
    );

    when(
      () => mockControlPlaneSDK.execute<cp.RegisterNotificationOutput>(
        any(that: isA<cp.RegisterNotificationCommand>()),
      ),
    ).thenAnswer(
      (_) async =>
          cp.RegisterNotificationOutput(notificationToken: notificationToken),
    );

    when(
      () => mockMediatorService.updateAcl(
        ownerDidManager: any(named: 'ownerDidManager'),
        mediatorDid: any(named: 'mediatorDid'),
        acl: any(named: 'acl'),
      ),
    ).thenAnswer((_) async {});

    final mockRecipientDoc = DidDocument.create(id: otherPartyPermanentDid);
    when(
      () => mockDidResolver.resolveDid(any()),
    ).thenAnswer((_) async => mockRecipientDoc);

    when(
      () => mockMediatorService.sendMessage(
        any(),
        senderDidManager: any(named: 'senderDidManager'),
        recipientDidDocument: any(named: 'recipientDidDocument'),
        mediatorDid: any(named: 'mediatorDid'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockChannelService.markChannelInauguratedForNonConnectionInitiator(
        any(),
        notificationToken: any(named: 'notificationToken'),
        otherPartyNotificationToken: any(named: 'otherPartyNotificationToken'),
        otherPartyPermanentChannelDid: any(
          named: 'otherPartyPermanentChannelDid',
        ),
        outboundMessageId: any(named: 'outboundMessageId'),
        otherPartyContactCard: any(named: 'otherPartyContactCard'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockOfferRepo.updateConnectionOffer(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockControlPlaneSDK.execute<cp.NotifyChannelCommandOutput>(
        any(that: isA<cp.NotifyChannelCommand>()),
      ),
    ).thenAnswer((_) async => cp.NotifyChannelCommandOutput(success: true));
  });

  group('processMessage joinChannelRoom transport guard', () {
    test('calls joinChannelRoom when transport is matrix', () async {
      final channel = createChannel(transport: ChannelTransport.matrix);

      when(
        () => mockMatrixService.joinChannelRoom(
          didManager: any(named: 'didManager'),
          channelDid: any(named: 'channelDid'),
          otherPartyChannelDid: any(named: 'otherPartyChannelDid'),
        ),
      ).thenAnswer((_) async => '!room:matrix.test');

      await handler.processMessage(
        createApprovalMessage(),
        event: event,
        connection: connectionOffer,
        channel: channel,
      );

      verify(
        () => mockMatrixService.joinChannelRoom(
          didManager: mockPermanentDidManager,
          channelDid: permanentChannelDid,
          otherPartyChannelDid: otherPartyPermanentDid,
        ),
      ).called(1);
    });

    test('does not call joinChannelRoom when transport is didcomm', () async {
      final channel = createChannel(transport: ChannelTransport.didcomm);

      await handler.processMessage(
        createApprovalMessage(),
        event: event,
        connection: connectionOffer,
        channel: channel,
      );

      verifyNever(
        () => mockMatrixService.joinChannelRoom(
          didManager: any(named: 'didManager'),
          channelDid: any(named: 'channelDid'),
          otherPartyChannelDid: any(named: 'otherPartyChannelDid'),
        ),
      );
    });
  });
}
