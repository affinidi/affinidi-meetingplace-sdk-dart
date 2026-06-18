import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_message.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_stream_subscription_wrapper.dart';
import 'package:meeting_place_core/src/service/message/message_service.dart';
import 'package:meeting_place_core/src/vdip/channel_activity_type.dart';
import 'package:meeting_place_core/src/vdip/vdip_client.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    show MediatorStreamProcessingResult;
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late VdipClient client;
  late MockMessageService mockMessageService;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockMediatorService mockMediatorService;
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
    mockMediatorService = MockMediatorService();
    mockWallet = MockWallet();
    mockDidManager = MockDidManager(did: senderDid);

    client = VdipClient(
      messageService: mockMessageService,
      channelService: mockChannelService,
      connectionManager: mockConnectionManager,
      wallet: mockWallet,
      mediatorService: mockMediatorService,
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

    test('emits a duplicate message id only once', () async {
      final messageId = const Uuid().v4();
      PlainTextMessage buildMessage() => PlainTextMessage(
        id: messageId,
        type: VdipIssuedCredentialMessage.messageType,
        body: {},
      );

      final received = <PlainTextMessage>[];
      final subscription = client.incomingMessages.listen(received.add);

      client.dispatch(buildMessage());
      client.dispatch(buildMessage());
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(received, hasLength(1));
    });

    test('emits messages with distinct ids', () async {
      final received = <PlainTextMessage>[];
      final subscription = client.incomingMessages.listen(received.add);

      client.dispatch(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          body: {},
        ),
      );
      client.dispatch(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          body: {},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(received, hasLength(2));
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

  group('subscribe', () {
    late FakeMediatorStreamSubscriptionWrapper fakeWrapper;
    late Channel channelWithPermanentDid;

    setUp(() {
      fakeWrapper = FakeMediatorStreamSubscriptionWrapper();
      channelWithPermanentDid = Channel(
        offerLink: 'offer',
        publishOfferDid: senderDid,
        mediatorDid: mediatorDid,
        status: ChannelStatus.approved,
        isConnectionInitiator: true,
        permanentChannelDid: senderDid,
        contactCard: ContactCard(
          did: recipientDid,
          type: 'individual',
          contactInfo: const {'fullName': 'Test'},
        ),
        type: ChannelType.individual,
      );
      when(
        () => mockMediatorService.subscribe(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
        ),
      ).thenAnswer((_) async => fakeWrapper);
    });

    test('returns the subscription from mediatorService', () async {
      final result = await client.subscribe(channelWithPermanentDid);
      expect(result, same(fakeWrapper));
    });

    test('calls mediatorService.subscribe with correct parameters', () async {
      await client.subscribe(channelWithPermanentDid);

      verify(
        () => mockMediatorService.subscribe(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
        ),
      ).called(1);
    });

    test('is idempotent — second call reuses existing subscription', () async {
      final first = await client.subscribe(channelWithPermanentDid);
      final second = await client.subscribe(channelWithPermanentDid);

      expect(second, same(first));
      verify(
        () => mockMediatorService.subscribe(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
        ),
      ).called(1);
    });

    test('throws StateError when channel has no permanentChannelDid', () async {
      await expectLater(
        () => client.subscribe(channel),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('unsubscribe', () {
    late FakeMediatorStreamSubscriptionWrapper fakeWrapper;
    late Channel channelWithPermanentDid;

    setUp(() {
      fakeWrapper = FakeMediatorStreamSubscriptionWrapper();
      channelWithPermanentDid = Channel(
        offerLink: 'offer',
        publishOfferDid: senderDid,
        mediatorDid: mediatorDid,
        status: ChannelStatus.approved,
        isConnectionInitiator: true,
        permanentChannelDid: senderDid,
        contactCard: ContactCard(
          did: recipientDid,
          type: 'individual',
          contactInfo: const {'fullName': 'Test'},
        ),
        type: ChannelType.individual,
      );
      when(
        () => mockMediatorService.subscribe(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
        ),
      ).thenAnswer((_) async => fakeWrapper);
    });

    test('disposes the subscription wrapper', () async {
      await client.subscribe(channelWithPermanentDid);
      await client.unsubscribe();

      expect(fakeWrapper.disposed, isTrue);
    });

    test('is a no-op when not subscribed', () async {
      await expectLater(client.unsubscribe(), completes);
    });

    test('allows re-subscribing after unsubscribe', () async {
      await client.subscribe(channelWithPermanentDid);
      await client.unsubscribe();

      final secondWrapper = FakeMediatorStreamSubscriptionWrapper();
      when(
        () => mockMediatorService.subscribe(
          didManager: mockDidManager,
          mediatorDid: mediatorDid,
        ),
      ).thenAnswer((_) async => secondWrapper);

      final result = await client.subscribe(channelWithPermanentDid);
      expect(result, same(secondWrapper));
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

class MockMediatorService extends Mock implements MediatorService {}

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

class FakeMediatorStreamSubscriptionWrapper extends Fake
    implements MediatorStreamSubscriptionWrapper {
  bool disposed = false;
  final _controller = StreamController<MediatorMessage>.broadcast();

  @override
  bool get isClosed => disposed;

  @override
  Stream<MediatorMessage> get stream => _controller.stream;

  @override
  StreamSubscription<MediatorMessage> listen(
    FutureOr<MediatorStreamProcessingResult> Function(MediatorMessage) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      (msg) async => onData(msg),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  StreamSubscription<MediatorMessage> timeout(
    Duration timeLimit,
    void Function()? onTimeout,
  ) => throw UnimplementedError();

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!_controller.isClosed) await _controller.close();
  }
}
