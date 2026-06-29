import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/message/message_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';
import 'event_handler/mocks/mocks.dart';

class MockMessageService extends Mock implements MessageService {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockDIDCommTransport extends Mock implements DIDCommTransport {}

class _MockDidManager extends Mock implements DidManager {}

class _FakeChannel extends Fake implements Channel {}

const _testDid = 'did:test:alice';
const _testEventId = '\$evt-1';

Channel _matrixChannel({
  String? permanentDid = _testDid,
  String? otherPartyPermanentDid = 'did:test:bob',
}) {
  return Channel(
    offerLink: 'offer',
    publishOfferDid: 'pubDid',
    mediatorDid: 'medDid',
    status: ChannelStatus.inaugurated,
    contactCard: ContactCardFixture.getContactCardFixture(),
    type: ChannelType.individual,
    transport: ChannelTransport.matrix,
    isConnectionInitiator: true,
    permanentChannelDid: permanentDid,
    otherPartyPermanentChannelDid: otherPartyPermanentDid,
  );
}

Channel _didcommChannel() {
  return Channel(
    offerLink: 'offer',
    publishOfferDid: 'pubDid',
    mediatorDid: 'medDid',
    status: ChannelStatus.inaugurated,
    contactCard: ContactCardFixture.getContactCardFixture(),
    type: ChannelType.individual,
    transport: ChannelTransport.didcomm,
    isConnectionInitiator: true,
    permanentChannelDid: _testDid,
    otherPartyPermanentChannelDid: 'did:test:bob',
  );
}

void main() {
  late MockMatrixService matrixService;
  late MockMessageService messageService;
  late MockChannelService channelService;
  late MockGroupRepository groupRepository;
  late MockDIDCommTransport didcomm;
  late _MockDidManager didManager;
  late MessagingService messagingService;

  setUpAll(() {
    registerFallbackValue(_MockDidManager());
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      const IndividualChannelNotification(
        recipientDid: 'did:test:fb',
        type: 'chat-activity',
      ),
    );
  });

  setUp(() {
    matrixService = MockMatrixService();
    messageService = MockMessageService();
    channelService = MockChannelService();
    groupRepository = MockGroupRepository();
    didcomm = MockDIDCommTransport();
    didManager = _MockDidManager();

    messagingService = MessagingService(
      channelTransport: matrixService,
      messageService: messageService,
      channelService: channelService,
      groupRepository: groupRepository,
      didcomm: didcomm,
      getDidManager: (_) async => didManager,
    );
  });

  group('sendMediaMessage (matrix)', () {
    test('uploads via sendFile and returns the event id', () async {
      final channel = _matrixChannel();
      when(
        () => matrixService.sendFile(
          channel: any(named: 'channel'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          didManager: any(named: 'didManager'),
          extraContent: any(named: 'extraContent'),
        ),
      ).thenAnswer((_) async => _testEventId);

      final eventId = await messagingService.sendMediaMessage(
        channel,
        Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
        filename: 'pic.png',
        caption: 'a caption',
      );

      expect(eventId, equals(_testEventId));
      verify(
        () => matrixService.sendFile(
          channel: any(named: 'channel'),
          bytes: any(named: 'bytes'),
          contentType: 'image/png',
          filename: 'pic.png',
          didManager: any(named: 'didManager'),
          extraContent: {'body': 'a caption'},
        ),
      ).called(1);
    });

    test('throws StateError when channel has no permanentChannelDid', () async {
      final channel = _matrixChannel(permanentDid: null);
      await expectLater(
        () => messagingService.sendMediaMessage(
          channel,
          Uint8List.fromList([1]),
          contentType: 'image/png',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('calls notifyChannel when notification is provided', () async {
      final channel = _matrixChannel();
      when(
        () => matrixService.sendFile(
          channel: any(named: 'channel'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          didManager: any(named: 'didManager'),
          extraContent: any(named: 'extraContent'),
        ),
      ).thenAnswer((_) async => _testEventId);
      when(() => messageService.notifyChannel(any())).thenAnswer((_) async {});

      const notification = IndividualChannelNotification(
        recipientDid: 'did:test:bob',
        type: 'chat-activity',
      );

      await messagingService.sendMediaMessage(
        channel,
        Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
        notification: notification,
      );

      // notifyChannel is fired unawaited; give the microtask queue a turn.
      await Future<void>.delayed(Duration.zero);

      verify(() => messageService.notifyChannel(notification)).called(1);
    });

    test('does not call notifyChannel when notification is null', () async {
      final channel = _matrixChannel();
      when(
        () => matrixService.sendFile(
          channel: any(named: 'channel'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          didManager: any(named: 'didManager'),
          extraContent: any(named: 'extraContent'),
        ),
      ).thenAnswer((_) async => _testEventId);

      await messagingService.sendMediaMessage(
        channel,
        Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
      );

      verifyNever(() => messageService.notifyChannel(any()));
    });
  });

  group('sendMediaMessage (didcomm)', () {
    test('throws UnimplementedError until DIDComm path lands', () async {
      final channel = _didcommChannel();
      await expectLater(
        () => messagingService.sendMediaMessage(
          channel,
          Uint8List.fromList([1]),
          contentType: 'image/png',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('downloadMedia', () {
    test('delegates to matrixService.downloadFile', () async {
      final channel = _matrixChannel();
      final bytes = Uint8List.fromList([7, 8, 9]);
      when(
        () => matrixService.downloadFile(
          channel: any(named: 'channel'),
          fileId: any(named: 'fileId'),
          didManager: any(named: 'didManager'),
        ),
      ).thenAnswer((_) async => bytes);

      final result = await messagingService.downloadMedia(
        channel,
        const MatrixEventMediaReference(_testEventId),
      );

      expect(result, equals(bytes));
      verify(
        () => matrixService.downloadFile(
          channel: any(named: 'channel'),
          fileId: _testEventId,
          didManager: any(named: 'didManager'),
        ),
      ).called(1);
    });

    test('throws UnimplementedError for DIDComm channels', () async {
      await expectLater(
        () => messagingService.downloadMedia(
          _didcommChannel(),
          const MatrixEventMediaReference(_testEventId),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
