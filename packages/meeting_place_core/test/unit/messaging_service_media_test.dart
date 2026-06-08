import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/sdk/sdk_error_handler.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/matrix/media/media.dart';
import 'package:meeting_place_core/src/service/message/message_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

class MockMatrixService extends Mock implements MatrixService {}

class MockMessageService extends Mock implements MessageService {}

class MockChannelService extends Mock implements ChannelService {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockDIDCommTransport extends Mock implements DIDCommTransport {}

class MockDidManager extends Mock implements DidManager {}

class MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

const _testRoomId = '!room:matrix.example.com';
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
  late MockDidManager didManager;
  late MessagingService messagingService;

  setUpAll(() {
    registerFallbackValue(MockDidManager());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    matrixService = MockMatrixService();
    messageService = MockMessageService();
    channelService = MockChannelService();
    groupRepository = MockGroupRepository();
    didcomm = MockDIDCommTransport();
    didManager = MockDidManager();

    messagingService = MessagingService(
      matrixService: matrixService,
      messageService: messageService,
      channelService: channelService,
      groupRepository: groupRepository,
      didcomm: didcomm,
      getDidManager: (_) async => didManager,
      errorHandler: SDKErrorHandler(logger: MockLogger()),
    );
  });

  group('sendMediaMessage (matrix)', () {
    test('uploads via sendFileEvent and returns the event id', () async {
      final channel = _matrixChannel();
      when(
        () => matrixService.getMediaConfig(didManager: didManager),
      ).thenAnswer((_) async => 1024);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: didManager,
          channel: channel,
        ),
      ).thenAnswer((_) async => _testRoomId);
      when(
        () => matrixService.sendFileEvent(
          _testRoomId,
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          didManager: didManager,
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
        () => matrixService.sendFileEvent(
          _testRoomId,
          bytes: any(named: 'bytes'),
          contentType: 'image/png',
          filename: 'pic.png',
          didManager: didManager,
          extraContent: {'body': 'a caption'},
        ),
      ).called(1);
    });

    test(
      'throws MediaException.tooLarge when bytes exceed homeserver limit',
      () async {
        final channel = _matrixChannel();
        when(
          () => matrixService.getMediaConfig(didManager: didManager),
        ).thenAnswer((_) async => 8);

        await expectLater(
          () => messagingService.sendMediaMessage(
            channel,
            Uint8List(64),
            contentType: 'image/png',
          ),
          throwsA(
            isA<MeetingPlaceCoreSDKException>().having(
              (e) => e.innerException,
              'innerException',
              isA<MatrixMediaException>().having(
                (e) => e.code,
                'code',
                MatrixMediaException.codeTooLarge,
              ),
            ),
          ),
        );

        verifyNever(
          () => matrixService.sendFileEvent(
            any(),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
            didManager: any(named: 'didManager'),
            extraContent: any(named: 'extraContent'),
          ),
        );
      },
    );

    test('throws StateError when channel has no permanentChannelDid', () async {
      final channel = _matrixChannel(permanentDid: null);
      await expectLater(
        () => messagingService.sendMediaMessage(
          channel,
          Uint8List.fromList([1]),
          contentType: 'image/png',
        ),
        throwsA(
          isA<MeetingPlaceCoreSDKException>().having(
            (e) => e.innerException,
            'innerException',
            isA<StateError>(),
          ),
        ),
      );
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
        throwsA(
          isA<MeetingPlaceCoreSDKException>().having(
            (e) => e.innerException,
            'innerException',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });
  });

  group('downloadMedia', () {
    test('delegates to matrixService.downloadFileForEvent', () async {
      final channel = _matrixChannel();
      final bytes = Uint8List.fromList([7, 8, 9]);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: didManager,
          channel: channel,
        ),
      ).thenAnswer((_) async => _testRoomId);
      when(
        () => matrixService.downloadFileForEvent(
          _testRoomId,
          _testEventId,
          didManager: didManager,
        ),
      ).thenAnswer((_) async => bytes);

      final result = await messagingService.downloadMedia(
        channel,
        const MatrixEventMediaReference(_testEventId),
      );

      expect(result, equals(bytes));
    });

    test('throws UnimplementedError for DIDComm channels', () async {
      await expectLater(
        () => messagingService.downloadMedia(
          _didcommChannel(),
          const MatrixEventMediaReference(_testEventId),
        ),
        throwsA(
          isA<MeetingPlaceCoreSDKException>().having(
            (e) => e.innerException,
            'innerException',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });
  });
}
