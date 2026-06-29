import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_service.dart';
import 'package:meeting_place_core/src/service/connection_service.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:meeting_place_core/src/service/identity/model/permanent_identity.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_acl_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class _MockControlPlaneSDK extends Mock implements cp.ControlPlaneSDK {}

class _MockMediatorSDK extends Mock implements MeetingPlaceMediatorSDK {}

class _MockMediatorAclService extends Mock implements MediatorAclService {}

class _MockIdentityService extends Mock implements IdentityService {}

class _MockConnectionOfferService extends Mock
    implements ConnectionOfferService {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockChannelService extends Mock implements ChannelService {}

class _MockMeetingPlaceTransport extends Mock
    implements MeetingPlaceTransport {}

class _MockWallet extends Mock implements Wallet {}

class _MockDidManager extends Mock implements DidManager {}

class _MockDidDocument extends Mock implements DidDocument {}

class _FakePlainTextMessage extends Fake implements PlainTextMessage {}

class _FakeChannel extends Fake implements Channel {}

void main() {
  late _MockConnectionManager mockConnectionManager;
  late _MockConnectionOfferRepository mockOfferRepo;
  late _MockControlPlaneSDK mockControlPlaneSDK;
  late _MockMediatorSDK mockMediatorSDK;
  late _MockMediatorAclService mockMediatorAclService;
  late _MockIdentityService mockIdentityService;
  late _MockConnectionOfferService mockOfferService;
  late _MockDidResolver mockDidResolver;
  late _MockChannelService mockChannelService;
  late _MockMeetingPlaceTransport mockMeetingPlaceTransport;
  late _MockWallet mockWallet;
  late ConnectionService service;

  setUp(() {
    mockConnectionManager = _MockConnectionManager();
    mockOfferRepo = _MockConnectionOfferRepository();
    mockControlPlaneSDK = _MockControlPlaneSDK();
    mockMediatorSDK = _MockMediatorSDK();
    mockMediatorAclService = _MockMediatorAclService();
    mockIdentityService = _MockIdentityService();
    mockOfferService = _MockConnectionOfferService();
    mockDidResolver = _MockDidResolver();
    mockChannelService = _MockChannelService();
    mockMeetingPlaceTransport = _MockMeetingPlaceTransport();
    mockWallet = _MockWallet();

    service = ConnectionService(
      connectionManager: mockConnectionManager,
      connectionOfferRepository: mockOfferRepo,
      controlPlaneSDK: mockControlPlaneSDK,
      mediatorSDK: mockMediatorSDK,
      mediatorAclService: mockMediatorAclService,
      identityService: mockIdentityService,
      offerService: mockOfferService,
      didResolver: mockDidResolver,
      channelService: mockChannelService,
      channelTransport: mockMeetingPlaceTransport,
    );

    registerFallbackValue(_MockDidManager());
    registerFallbackValue(_MockDidDocument());
    registerFallbackValue(_FakePlainTextMessage());
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(_MockWallet());
    registerFallbackValue(ChannelTransport.didcomm);
    registerFallbackValue(
      cp.FinaliseAcceptanceCommand(
        mnemonic: '',
        offerLink: '',
        offerPublishedDid: '',
        otherPartyAcceptOfferDid: '',
        otherPartyPermanentChannelDid: '',
        device: cp.Device(
          deviceToken: '',
          platformType: cp.PlatformType.pushNotification,
        ),
      ),
    );
    registerFallbackValue(
      ConnectionOffer(
        offerName: '',
        offerLink: '',
        type: ConnectionOfferType.meetingPlaceInvitation,
        mnemonic: '',
        publishOfferDid: '',
        mediatorDid: '',
        oobInvitationMessage: '',
        contactCard: ContactCardFixture.getContactCardFixture(),
        status: ConnectionOfferStatus.published,
        ownedByMe: true,
        createdAt: DateTime.now().toUtc(),
        transport: ChannelTransport.didcomm,
      ),
    );
  });

  group('approveConnectionRequest', () {
    const offerLink = 'offer-link';
    const publishOfferDid = 'did:test:publish';
    const acceptOfferDid = 'did:test:accept';
    const otherPartyPermanentDid = 'did:test:other-permanent';
    const permanentDid = 'did:test:permanent';
    const mediatorDid = 'did:test:mediator';
    const mnemonic = 'test-mnemonic';

    late _MockDidManager mockPublishDidManager;
    late _MockDidManager mockPermanentDidManager;
    late _MockDidDocument mockPublishDidDocument;
    late _MockDidDocument mockPermanentDidDocument;
    late _MockDidDocument mockRecipientDidDocument;

    Channel createChannel({required ChannelTransport transport}) => Channel(
      offerLink: offerLink,
      publishOfferDid: publishOfferDid,
      mediatorDid: mediatorDid,
      status: ChannelStatus.waitingForApproval,
      isConnectionInitiator: true,
      contactCard: ContactCardFixture.getContactCardFixture(),
      type: ChannelType.individual,
      transport: transport,
      acceptOfferDid: acceptOfferDid,
      otherPartyPermanentChannelDid: otherPartyPermanentDid,
    );

    ConnectionOffer createOffer({required ChannelTransport transport}) =>
        ConnectionOffer(
          offerName: 'Test Offer',
          offerLink: offerLink,
          type: ConnectionOfferType.meetingPlaceInvitation,
          mnemonic: mnemonic,
          publishOfferDid: publishOfferDid,
          mediatorDid: mediatorDid,
          oobInvitationMessage: '',
          contactCard: ContactCardFixture.getContactCardFixture(),
          status: ConnectionOfferStatus.published,
          ownedByMe: true,
          createdAt: DateTime.now().toUtc(),
          transport: transport,
        );

    void setUpCommonMocks(ChannelTransport transport) {
      mockPublishDidManager = _MockDidManager();
      mockPermanentDidManager = _MockDidManager();
      mockPublishDidDocument = _MockDidDocument();
      mockPermanentDidDocument = _MockDidDocument();
      mockRecipientDidDocument = _MockDidDocument();

      when(() => mockPublishDidDocument.id).thenReturn(publishOfferDid);
      when(() => mockPermanentDidDocument.id).thenReturn(permanentDid);
      when(
        () => mockPublishDidManager.getDidDocument(),
      ).thenAnswer((_) async => mockPublishDidDocument);
      when(
        () => mockPermanentDidManager.getDidDocument(),
      ).thenAnswer((_) async => mockPermanentDidDocument);

      when(
        () => mockConnectionManager.getDidManagerForDid(mockWallet, any()),
      ).thenAnswer((_) async => mockPublishDidManager);

      when(
        () => mockOfferRepo.getConnectionOfferByOfferLink(offerLink),
      ).thenAnswer((_) async => createOffer(transport: transport));

      when(
        () => mockIdentityService.createPermanentIdentity(mockWallet),
      ).thenAnswer(
        (_) async => PermanentIdentity(
          didManager: mockPermanentDidManager,
          didDocument: mockPermanentDidDocument,
          matrixUserId: '@permanent:matrix.test',
        ),
      );

      when(
        () => mockMediatorAclService.addToAcl(
          didManager: any(named: 'didManager'),
          mediatorDid: any(named: 'mediatorDid'),
          granteeDids: any(named: 'granteeDids'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockDidResolver.resolveDid(any()),
      ).thenAnswer((_) async => mockRecipientDidDocument);

      when(
        () => mockMediatorSDK.sendMessage(
          any(),
          senderDidManager: any(named: 'senderDidManager'),
          recipientDidDocument: any(named: 'recipientDidDocument'),
          mediatorDid: any(named: 'mediatorDid'),
          next: any(named: 'next'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockControlPlaneSDK.device).thenReturn(
        cp.Device(
          deviceToken: 'token',
          platformType: cp.PlatformType.pushNotification,
        ),
      );

      when(
        () => mockControlPlaneSDK.execute<cp.FinaliseAcceptanceOutput>(
          any(that: isA<cp.FinaliseAcceptanceCommand>()),
        ),
      ).thenAnswer(
        (_) async => cp.FinaliseAcceptanceOutput(
          success: true,
          notificationToken: 'notification-token',
        ),
      );

      when(
        () => mockOfferRepo.updateConnectionOffer(any()),
      ).thenAnswer((_) async {});

      when(
        () => mockChannelService.markChannelApprovedForConnectionInitiator(
          any(),
          permanentChannelDid: any(named: 'permanentChannelDid'),
          otherPartyPermanentChannelDid: any(
            named: 'otherPartyPermanentChannelDid',
          ),
          notificationToken: any(named: 'notificationToken'),
        ),
      ).thenAnswer((_) async {});
    }

    test('calls setupChannel when channel uses a channel transport', () async {
      setUpCommonMocks(ChannelTransport.matrix);
      final channel = createChannel(transport: ChannelTransport.matrix);

      when(
        () => mockMeetingPlaceTransport.setupChannel(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
          participantDids: any(named: 'participantDids'),
        ),
      ).thenAnswer((_) async {});

      await service.approveConnectionRequest(
        wallet: mockWallet,
        channel: channel,
      );

      verify(
        () => mockMeetingPlaceTransport.setupChannel(
          channel: any(named: 'channel'),
          didManager: mockPermanentDidManager,
          participantDids: [otherPartyPermanentDid],
        ),
      ).called(1);
    });

    test('skips setupChannel when transport is didcomm', () async {
      setUpCommonMocks(ChannelTransport.didcomm);
      final channel = createChannel(transport: ChannelTransport.didcomm);

      await service.approveConnectionRequest(
        wallet: mockWallet,
        channel: channel,
      );

      verifyNever(
        () => mockMeetingPlaceTransport.setupChannel(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
          participantDids: any(named: 'participantDids'),
        ),
      );
    });
  });

  group('unlink', () {
    const permanentChannelDid = 'did:test:my-permanent';
    const otherPartyPermanentDid = 'did:test:other-permanent';
    const offerLink = 'offer-link';
    const mediatorDid = 'did:test:mediator';

    late _MockDidManager mockDidManager;

    Channel createUnlinkChannel({
      required ChannelTransport transport,
      String? notificationToken,
    }) => Channel(
      offerLink: offerLink,
      publishOfferDid: 'did:test:publish',
      mediatorDid: mediatorDid,
      status: ChannelStatus.approved,
      isConnectionInitiator: true,
      contactCard: ContactCardFixture.getContactCardFixture(),
      type: ChannelType.individual,
      transport: transport,
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentDid,
      notificationToken: notificationToken,
    );

    void setUpUnlinkMocks() {
      mockDidManager = _MockDidManager();

      when(
        () => mockOfferRepo.getConnectionOfferByOfferLink(offerLink),
      ).thenAnswer((_) async => null);

      when(
        () => mockMediatorAclService.removePermissionFromChannel(
          wallet: any(named: 'wallet'),
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockChannelService.deleteChannel(any()),
      ).thenAnswer((_) async {});

      when(
        () => mockConnectionManager.getDidManagerForDid(
          mockWallet,
          permanentChannelDid,
        ),
      ).thenAnswer((_) async => mockDidManager);

      when(
        () => mockMeetingPlaceTransport.leaveChannel(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
        ),
      ).thenAnswer((_) async {});
    }

    test('calls leaveChannel when channel uses a channel transport', () async {
      setUpUnlinkMocks();
      final channel = createUnlinkChannel(transport: ChannelTransport.matrix);

      await service.unlink(wallet: mockWallet, channel: channel);

      verify(
        () => mockMeetingPlaceTransport.leaveChannel(
          channel: any(named: 'channel'),
          didManager: mockDidManager,
        ),
      ).called(1);
    });

    test('skips leaveChannel when transport is didcomm', () async {
      setUpUnlinkMocks();
      final channel = createUnlinkChannel(transport: ChannelTransport.didcomm);

      await service.unlink(wallet: mockWallet, channel: channel);

      verifyNever(
        () => mockMeetingPlaceTransport.leaveChannel(
          channel: any(named: 'channel'),
          didManager: any(named: 'didManager'),
        ),
      );
    });
  });
}
