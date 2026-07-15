import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/identity/did_web_document_service.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_stream_subscription_wrapper.dart';
import 'package:meeting_place_core/src/service/message/message_service.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    show AclBody;
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockMatrixService extends Mock implements MatrixService {}

class _MockWallet extends Mock implements Wallet {}

class _MockDidManager extends Mock implements DidManager {}

class _MockDidDocument extends Mock implements DidDocument {}

class _FakeDidManager extends Fake implements DidManager {}

class _FakeDidDocument extends Fake implements DidDocument {}

class _FakeAclBody extends Fake implements AclBody {}

class _MockDidWebDocumentService extends Mock
    implements DidWebDocumentService {}

class _MockMessageService extends Mock implements MessageService {}

class _MockMediatorService extends Mock implements MediatorService {}

class _MockMediatorStreamSubscriptionWrapper extends Mock
    implements MediatorStreamSubscriptionWrapper {}

class _FakePlainTextMessage extends Fake implements PlainTextMessage {}

const _agentDid = 'did:web:personal-ai-agent.affinidi.com';

void main() {
  late _MockConnectionManager mockConnectionManager;
  late _MockMatrixService mockMatrixService;
  late _MockWallet mockWallet;
  late _MockDidManager mockDidManager;
  late _MockDidDocument mockDidDocument;
  late _MockDidWebDocumentService mockDidDocumentService;
  late _MockMessageService mockMessageService;
  late _MockMediatorService mockMediatorService;
  late _MockMediatorStreamSubscriptionWrapper mockSubscription;
  late IdentityService service;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(_FakeDidManager());
    registerFallbackValue(_FakeDidDocument());
    registerFallbackValue(_FakePlainTextMessage());
    registerFallbackValue(_FakeAclBody());
  });

  setUp(() {
    mockConnectionManager = _MockConnectionManager();
    mockMatrixService = _MockMatrixService();
    mockWallet = _MockWallet();
    mockDidManager = _MockDidManager();
    mockDidDocument = _MockDidDocument();
    mockDidDocumentService = _MockDidWebDocumentService();
    mockMessageService = _MockMessageService();
    mockMediatorService = _MockMediatorService();
    mockSubscription = _MockMediatorStreamSubscriptionWrapper();

    service = IdentityService(
      connectionManager: mockConnectionManager,
      matrixService: mockMatrixService,
      didWebDocumentService: mockDidDocumentService,
      didWebBaseHost: Uri.parse('https://example.com'),
      messageService: mockMessageService,
      mediatorService: mockMediatorService,
      mediatorDid: 'did:test:mediator',
      agentDid: _agentDid,
    );

    when(() => mockDidDocument.id).thenReturn('did:test:permanent');
    when(
      () => mockConnectionManager.generateDidWeb(
        mockWallet,
        baseHost: any(named: 'baseHost'),
      ),
    ).thenAnswer((_) async => mockDidManager);
    when(
      () => mockDidManager.getDidDocument(),
    ).thenAnswer((_) async => mockDidDocument);
    when(
      () => mockDidDocumentService.register(
        didManager: any(named: 'didManager'),
        didDocument: any(named: 'didDocument'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockMediatorService.updateAcl(
        ownerDidManager: any(named: 'ownerDidManager'),
        acl: any(named: 'acl'),
        mediatorDid: any(named: 'mediatorDid'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockMediatorService.subscribe(
        didManager: any(named: 'didManager'),
        mediatorDid: any(named: 'mediatorDid'),
      ),
    ).thenAnswer((_) async => mockSubscription);

    when(() => mockSubscription.dispose()).thenAnswer((_) async {});

    when(
      () => mockMessageService.sendMessage(
        any(),
        senderDidManager: any(named: 'senderDidManager'),
        recipientDid: any(named: 'recipientDid'),
        mediatorDid: any(named: 'mediatorDid'),
      ),
    ).thenAnswer((_) async {});
  });

  group('createPermanentIdentity', () {
    late ContactCard contactCard;

    setUp(() {
      contactCard = ContactCardFixture.getContactCardFixture();
    });

    MediatorMessage buildAgentResponse(String agentDid) {
      final payload = PlainTextMessage(
        id: 'response-id',
        type: Uri.parse(
          'https://affinidi.com/didcomm/protocols/'
          'meeting-place-core/1.0/'
          'agent-create-channel-identity-response',
        ),
        body: {'did': agentDid},
      );
      return MediatorMessage(plainTextMessage: payload);
    }

    test(
      'calls loginWithDid and notifies agent when transport is matrix',
      () async {
        when(
          () => mockMatrixService.loginWithDid(any()),
        ).thenAnswer((_) async => '@user:matrix.test');

        when(
          () => mockSubscription.stream,
        ).thenAnswer((_) => Stream.value(buildAgentResponse('did:test:agent')));

        final result = await service.createPermanentIdentity(
          mockWallet,
          transport: ChannelTransport.matrix,
          offerLink: 'https://example.com/offer',
          publishOfferDid: 'did:test:publish',
          contactCard: contactCard,
        );

        verify(() => mockMatrixService.loginWithDid(mockDidManager)).called(1);
        expect(result.matrixUserId, equals('@user:matrix.test'));
        expect(result.didManager, equals(mockDidManager));
        expect(result.didDocument, equals(mockDidDocument));
        expect(result.agentDid, equals('did:test:agent'));
      },
    );

    test('does not call loginWithDid and notifies agent '
        'when transport is didcomm', () async {
      when(
        () => mockSubscription.stream,
      ).thenAnswer((_) => Stream.value(buildAgentResponse('did:test:agent')));

      final result = await service.createPermanentIdentity(
        mockWallet,
        transport: ChannelTransport.didcomm,
        offerLink: 'https://example.com/offer',
        publishOfferDid: 'did:test:publish',
        contactCard: contactCard,
      );
      expect(result.matrixUserId, isNull);
      expect(result.didManager, equals(mockDidManager));
      expect(result.didDocument, equals(mockDidDocument));
      expect(result.agentDid, equals('did:test:agent'));
    });

    test('throws when agent does not respond', () async {
      when(
        () => mockSubscription.stream,
      ).thenAnswer((_) => const Stream<MediatorMessage>.empty());

      await expectLater(
        service.createPermanentIdentity(
          mockWallet,
          transport: ChannelTransport.didcomm,
          offerLink: 'https://example.com/offer',
          publishOfferDid: 'did:test:publish',
          contactCard: contactCard,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('sends request with correct body to agent DID', () async {
      when(
        () => mockSubscription.stream,
      ).thenAnswer((_) => Stream.value(buildAgentResponse('did:test:agent')));

      await service.createPermanentIdentity(
        mockWallet,
        transport: ChannelTransport.didcomm,
        offerLink: 'https://example.com/offer',
        publishOfferDid: 'did:test:publish',
        contactCard: contactCard,
      );

      final captured = verify(
        () => mockMessageService.sendMessage(
          captureAny(),
          senderDidManager: any(named: 'senderDidManager'),
          recipientDid: captureAny(named: 'recipientDid'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).captured;

      final message = captured[0] as PlainTextMessage;
      final recipientDid = captured[1] as String;

      expect(
        message.type.toString(),
        equals(
          'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/agent-create-channel-identity-request',
        ),
      );
      expect(message.body!['channelDid'], equals('did:test:permanent'));
      expect(recipientDid, equals(_agentDid));
    });

    test(
      'includes offerLink, publishOfferDid and contactCard in request body',
      () async {
        when(
          () => mockSubscription.stream,
        ).thenAnswer((_) => Stream.value(buildAgentResponse('did:test:agent')));

        final contactCard = ContactCardFixture.getContactCardFixture();

        await service.createPermanentIdentity(
          mockWallet,
          transport: ChannelTransport.didcomm,
          offerLink: 'https://example.com/offer',
          publishOfferDid: 'did:test:publish',
          contactCard: contactCard,
        );

        final captured = verify(
          () => mockMessageService.sendMessage(
            captureAny(),
            senderDidManager: any(named: 'senderDidManager'),
            recipientDid: any(named: 'recipientDid'),
            mediatorDid: any(named: 'mediatorDid'),
          ),
        ).captured;

        final message = captured[0] as PlainTextMessage;
        final body = Map<String, dynamic>.from(message.body!);
        final contactCardBody = Map<String, dynamic>.from(
          body['contactCard'] as Map,
        );

        expect(body['offerLink'], equals('https://example.com/offer'));
        expect(body['publishOfferDid'], equals('did:test:publish'));
        expect(body['contactCard'], isA<Map<String, dynamic>>());
        expect(contactCardBody['did'], equals(contactCard.did));
      },
    );

    test('skips agent handshake when no agentDid is configured', () async {
      final serviceWithoutAgent = IdentityService(
        connectionManager: mockConnectionManager,
        matrixService: mockMatrixService,
        didWebDocumentService: mockDidDocumentService,
        didWebBaseHost: Uri.parse('https://example.com'),
        messageService: mockMessageService,
        mediatorService: mockMediatorService,
        mediatorDid: 'did:test:mediator',
      );

      final result = await serviceWithoutAgent.createPermanentIdentity(
        mockWallet,
        transport: ChannelTransport.didcomm,
      );

      verifyNever(
        () => mockMediatorService.subscribe(
          didManager: any(named: 'didManager'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      );
      verifyNever(
        () => mockMessageService.sendMessage(
          any(),
          senderDidManager: any(named: 'senderDidManager'),
          recipientDid: any(named: 'recipientDid'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      );
      expect(result.agentDid, isNull);
    });
  });
}
