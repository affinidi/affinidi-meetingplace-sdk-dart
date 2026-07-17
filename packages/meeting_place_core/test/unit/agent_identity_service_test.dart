import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/agent_identity_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_acl_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

class _MockIdentityService extends Mock implements IdentityService {}

class _MockMediatorAclService extends Mock implements MediatorAclService {}

class _MockDIDCommTransport extends Mock implements DIDCommTransport {}

class _MockChannelRepository extends Mock implements ChannelRepository {}

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockWallet extends Mock implements Wallet {}

class _MockMatrixService extends Mock implements MatrixService {}

class _MockDidManager extends Mock implements DidManager {}

class _MockDidDocument extends Mock implements DidDocument {}

class _FakeDidManager extends Fake implements DidManager {}

class _FakePlainTextMessage extends Fake implements PlainTextMessage {}

class _FakeChannel extends Fake implements Channel {}

const _agentDid = 'did:test:agent';
const _channelDid = 'did:test:channel';
const _mediatorDid = 'did:test:mediator';
const _agentControllerDid = 'did:test:controller';
const _newPermanentChannelDid = 'did:web:new.example.com';

void main() {
  late _MockIdentityService mockIdentityService;
  late _MockMediatorAclService mockMediatorAclService;
  late _MockDIDCommTransport mockDIDCommTransport;
  late _MockChannelRepository mockChannelRepository;
  late _MockConnectionManager mockConnectionManager;
  late _MockWallet mockWallet;
  late _MockMatrixService mockMatrixService;
  late _MockDidManager mockDidManager;
  late _MockDidManager mockAgentDidManager;
  late _MockDidDocument mockDidDocument;
  late AgentIdentityService service;

  setUpAll(() {
    registerFallbackValue(_FakeDidManager());
    registerFallbackValue(_FakePlainTextMessage());
    registerFallbackValue(_FakeChannel());
  });

  setUp(() {
    mockIdentityService = _MockIdentityService();
    mockMediatorAclService = _MockMediatorAclService();
    mockDIDCommTransport = _MockDIDCommTransport();
    mockChannelRepository = _MockChannelRepository();
    mockConnectionManager = _MockConnectionManager();
    mockWallet = _MockWallet();
    mockDidManager = _MockDidManager();
    mockAgentDidManager = _MockDidManager();
    mockDidDocument = _MockDidDocument();
    mockMatrixService = _MockMatrixService();

    service = AgentIdentityService(
      identityService: mockIdentityService,
      mediatorAclService: mockMediatorAclService,
      didcommTransport: mockDIDCommTransport,
      channelRepository: mockChannelRepository,
      wallet: mockWallet,
      connectionManager: mockConnectionManager,
      matrixService: mockMatrixService,
    );

    when(
      () => mockIdentityService.generateDidWeb(mockWallet),
    ).thenAnswer((_) async => mockDidManager);

    when(
      () => mockConnectionManager.getDidManagerForDid(mockWallet, _agentDid),
    ).thenAnswer((_) async => mockAgentDidManager);

    when(
      () => mockDidManager.getDidDocument(),
    ).thenAnswer((_) async => mockDidDocument);

    when(() => mockDidDocument.id).thenReturn(_newPermanentChannelDid);

    when(
      () => mockMediatorAclService.addToAcl(
        didManager: any(named: 'didManager'),
        mediatorDid: any(named: 'mediatorDid'),
        granteeDids: any(named: 'granteeDids'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockDIDCommTransport.sendMessage(
        any(),
        senderDid: any(named: 'senderDid'),
        recipientDid: any(named: 'recipientDid'),
        mediatorDid: any(named: 'mediatorDid'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockChannelRepository.createChannel(any()),
    ).thenAnswer((_) async {});
  });

  group('createChannelIdentity', () {
    final contactCard = ContactCardFixture.getContactCardFixture();

    Future<void> callService() => service.createChannelIdentity(
      agentDid: _agentDid,
      otherPartyPermanentChannelDid: _channelDid,
      mediatorDid: _mediatorDid,
      agentControllerDid: _agentControllerDid,
      offerLink: 'https://example.com/offer',
      publishOfferDid: 'did:test:publish',
      contactCard: contactCard,
      transport: ChannelTransport.didcomm,
    );

    test('generates a new did:web via IdentityService', () async {
      await callService();

      verify(() => mockIdentityService.generateDidWeb(mockWallet)).called(1);
    });

    test(
      'grants otherPartyPermanentChannelDid access on the mediator',
      () async {
        await callService();

        final captured = verify(
          () => mockMediatorAclService.addToAcl(
            didManager: captureAny(named: 'didManager'),
            mediatorDid: captureAny(named: 'mediatorDid'),
            granteeDids: captureAny(named: 'granteeDids'),
          ),
        ).captured;

        // First call: permanent channel DID grants access to user + controller
        expect(captured[0], equals(mockDidManager)); // didManager
        expect(captured[1], equals([_channelDid, _agentControllerDid]));
        expect(captured[2], equals(_mediatorDid)); // mediatorDid
        // Second call: agent DID grants access to user's permanent channel DID
        expect(captured[3], equals(mockAgentDidManager)); // agent didManager
        expect(captured[4], equals([_channelDid])); // granteeDids
        expect(captured[5], equals(_mediatorDid)); // mediatorDid
      },
    );

    test('sends agent-create-channel-identity-response with new DID', () async {
      await callService();

      final captured = verify(
        () => mockDIDCommTransport.sendMessage(
          captureAny(),
          senderDid: captureAny(named: 'senderDid'),
          recipientDid: captureAny(named: 'recipientDid'),
          mediatorDid: captureAny(named: 'mediatorDid'),
        ),
      ).captured;

      final message = captured[0] as PlainTextMessage;
      expect(
        message.type.toString(),
        equals(
          'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/agent-create-channel-identity-response',
        ),
      );
      expect(message.body!['did'], equals(_newPermanentChannelDid));
      expect(captured[1], equals(_agentDid));
      expect(captured[2], equals(_channelDid));
      expect(captured[3], equals(_mediatorDid));
    });

    test('persists a channel linking the two permanent channel DIDs', () async {
      await callService();

      final captured = verify(
        () => mockChannelRepository.createChannel(captureAny()),
      ).captured;

      final channel = captured.single as Channel;
      expect(channel.permanentChannelDid, equals(_newPermanentChannelDid));
      expect(channel.mediatorDid, equals(_mediatorDid));
      expect(channel.status, equals(ChannelStatus.waitingForApproval));
      expect(channel.isConnectionInitiator, isFalse);
      expect(channel.transport, equals(ChannelTransport.didcomm));
    });

    test('persists channel with supplied offer and contact details', () async {
      await callService();

      final captured = verify(
        () => mockChannelRepository.createChannel(captureAny()),
      ).captured;

      final channel = captured.single as Channel;
      expect(channel.offerLink, equals('https://example.com/offer'));
      expect(channel.publishOfferDid, equals('did:test:publish'));
      expect(channel.contactCard?.did, equals(contactCard.did));
    });
  });
}
