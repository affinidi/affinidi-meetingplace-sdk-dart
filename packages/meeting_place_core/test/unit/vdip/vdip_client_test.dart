import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/message/message_service.dart';
import 'package:meeting_place_core/src/vdip/channel_activity_type.dart';
import 'package:meeting_place_core/src/vdip/vdip_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late VdipClient client;
  late MockMessageService mockMessageService;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockWallet mockWallet;
  late MockDidManager mockDidManager;

  const senderDid = 'did:key:sender';
  const recipientDid = 'did:key:recipient';
  const mediatorDid = 'did:web:mediator';

  final channel = Channel(
    offerLink: 'offer',
    publishOfferDid: senderDid,
    mediatorDid: mediatorDid,
    status: ChannelStatus.approved,
    isConnectionInitiator: true,
    contactCard: ContactCard(
      did: recipientDid,
      type: 'individual',
      contactInfo: const {'fullName': 'Test'},
    ),
    type: ChannelType.individual,
  );

  setUpAll(() {
    registerFallbackValue(
      PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse('https://example.com/fallback'),
        body: {},
      ),
    );
  });

  setUp(() {
    mockMessageService = MockMessageService();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockWallet = MockWallet();
    mockDidManager = MockDidManager(did: senderDid);

    client = VdipClient(
      messageService: mockMessageService,
      channelService: mockChannelService,
      connectionManager: mockConnectionManager,
      wallet: mockWallet,
    );

    when(
      () => mockConnectionManager.getDidManagerForDid(mockWallet, senderDid),
    ).thenAnswer((_) async => mockDidManager);

    when(
      () => mockChannelService.findChannelByDid(recipientDid),
    ).thenAnswer((_) async => channel);

    when(
      () => mockMessageService.sendMessage(
        any(),
        senderDidManager: mockDidManager,
        recipientDid: recipientDid,
        mediatorDid: mediatorDid,
        notifyChannelType: any(named: 'notifyChannelType'),
      ),
    ).thenAnswer((_) async {});
  });

  group('dispatch', () {
    test('emits message on incomingMessages stream', () async {
      final message = PlainTextMessage(
        id: const Uuid().v4(),
        type: VdipRequestIssuanceMessage.messageType,
        body: {},
      );

      final expectation = expectLater(
        client.incomingMessages,
        emits(same(message)),
      );
      client.dispatch(message);
      await expectation;
    });
  });

  group('requestIssuance', () {
    test('sends message with vdipRequestIssuance channel type', () async {
      await client.requestIssuance(
        senderDid: senderDid,
        recipientDid: recipientDid,
        options: const RequestCredentialsOptions(proposalId: 'proposal-1'),
      );

      verify(
        () => mockMessageService.sendMessage(
          any(),
          senderDidManager: mockDidManager,
          recipientDid: recipientDid,
          mediatorDid: mediatorDid,
          notifyChannelType: ChannelActivityType.vdipRequestIssuance,
        ),
      ).called(1);
    });

    test('resolves senderDidManager via connectionManager', () async {
      await client.requestIssuance(
        senderDid: senderDid,
        recipientDid: recipientDid,
        options: const RequestCredentialsOptions(proposalId: 'proposal-1'),
      );

      verify(
        () => mockConnectionManager.getDidManagerForDid(mockWallet, senderDid),
      ).called(1);
    });

    test('looks up channel by recipientDid', () async {
      await client.requestIssuance(
        senderDid: senderDid,
        recipientDid: recipientDid,
        options: const RequestCredentialsOptions(proposalId: 'proposal-1'),
      );

      verify(() => mockChannelService.findChannelByDid(recipientDid)).called(1);
    });
  });

  group('sendIssuedCredential', () {
    late MockVdipIssuedCredentialBody mockBody;

    setUp(() {
      mockBody = MockVdipIssuedCredentialBody();
      when(() => mockBody.toJson()).thenReturn({'credential': 'test-vc'});
    });

    test('sends message with vdipIssuedCredentials channel type', () async {
      await client.sendIssuedCredential(
        senderDid: senderDid,
        recipientDid: recipientDid,
        body: mockBody,
      );

      verify(
        () => mockMessageService.sendMessage(
          any(),
          senderDidManager: mockDidManager,
          recipientDid: recipientDid,
          mediatorDid: mediatorDid,
          notifyChannelType: ChannelActivityType.vdipIssuedCredentials,
        ),
      ).called(1);
    });

    test('resolves senderDidManager via connectionManager', () async {
      await client.sendIssuedCredential(
        senderDid: senderDid,
        recipientDid: recipientDid,
        body: mockBody,
      );

      verify(
        () => mockConnectionManager.getDidManagerForDid(mockWallet, senderDid),
      ).called(1);
    });
  });

  group('dispose', () {
    test('closes incomingMessages stream', () async {
      final isEmpty = client.incomingMessages.isEmpty;
      await client.dispose();
      expect(await isEmpty, isTrue);
    });

    test('dispatch after dispose is ignored', () async {
      final message = PlainTextMessage(
        id: const Uuid().v4(),
        type: VdipRequestIssuanceMessage.messageType,
        body: {},
      );

      await client.dispose();

      expect(() => client.dispatch(message), returnsNormally);
    });

    test('dispose can be called more than once', () async {
      await client.dispose();

      expect(client.dispose, returnsNormally);
    });
  });
}

// Mock classes
class MockMessageService extends Mock implements MessageService {}

class MockChannelService extends Mock implements ChannelService {}

class MockConnectionManager extends Mock implements ConnectionManager {}

class MockWallet extends Mock implements Wallet {}

class MockDidManager extends Mock implements DidManager {
  MockDidManager({required this.did});

  final String did;

  @override
  Future<DidDocument> getDidDocument() async {
    return DidDocument.create(id: did);
  }
}

class MockVdipIssuedCredentialBody extends Mock
    implements VdipIssuedCredentialBody {}
