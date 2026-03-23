import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_service.dart';
import 'package:meeting_place_core/src/service/connection_service.dart';
import 'package:meeting_place_core/src/service/group.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_service.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockWallet extends Mock implements Wallet {}

class MockConnectionManager extends Mock implements ConnectionManager {}

class MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockKeyRepository extends Mock implements KeyRepository {}

class MockChannelService extends Mock implements ChannelService {}

class MockConnectionOfferService extends Mock
    implements ConnectionOfferService {}

class MockConnectionService extends Mock implements ConnectionService {}

class MockControlPlaneSDK extends Mock implements cp.ControlPlaneSDK {}

class MockMeetingPlaceMediatorSDK extends Mock
    implements MeetingPlaceMediatorSDK {}

class MockDidResolver extends Mock implements DidResolver {}

class MockMatrixService extends Mock implements MatrixService {}

void main() {
  group('GroupService.sendGroupAttachment', () {
    late MockWallet wallet;
    late MockConnectionManager connectionManager;
    late MockConnectionOfferRepository connectionOfferRepository;
    late MockGroupRepository groupRepository;
    late MockKeyRepository keyRepository;
    late MockChannelService channelService;
    late MockConnectionOfferService connectionOfferService;
    late MockConnectionService connectionService;
    late MockControlPlaneSDK controlPlaneSDK;
    late MockMeetingPlaceMediatorSDK mediatorSDK;
    late MockDidResolver didResolver;
    late MockMatrixService matrixService;
    late GroupService service;

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
    });

    setUp(() {
      wallet = MockWallet();
      connectionManager = MockConnectionManager();
      connectionOfferRepository = MockConnectionOfferRepository();
      groupRepository = MockGroupRepository();
      keyRepository = MockKeyRepository();
      channelService = MockChannelService();
      connectionOfferService = MockConnectionOfferService();
      connectionService = MockConnectionService();
      controlPlaneSDK = MockControlPlaneSDK();
      mediatorSDK = MockMeetingPlaceMediatorSDK();
      didResolver = MockDidResolver();
      matrixService = MockMatrixService();

      service = GroupService(
        wallet: wallet,
        connectionManager: connectionManager,
        connectionOfferRepository: connectionOfferRepository,
        groupRepository: groupRepository,
        keyRepository: keyRepository,
        channelService: channelService,
        offerService: connectionOfferService,
        connectionService: connectionService,
        controlPlaneSDK: controlPlaneSDK,
        mediatorSDK: mediatorSDK,
        didResolver: didResolver,
        matrixService: matrixService,
      );
    });

    test('delegates attachment sending to MatrixService', () async {
      final attachment = Attachment(
        id: 'attachment-1',
        filename: 'voice-note.m4a',
        mediaType: 'audio/mp4',
        data: AttachmentData(
          base64: base64Encode([1, 2, 3, 4]),
          json: jsonEncode({'durationMs': 2500}),
        ),
      );
      final expected = Attachment(
        id: 'attachment-1',
        filename: 'voice-note.m4a',
        mediaType: 'audio/mp4',
        format: AttachmentFormat.matrixAudio.value,
        data: AttachmentData(
          base64: base64Encode([1, 2, 3, 4]),
          json: jsonEncode({'durationMs': 2500}),
          links: [Uri.parse('mxc://example.com/audio123')],
        ),
        byteCount: 4,
      );

      when(
        () => matrixService.sendAttachment(
          roomId: '!room:example.com',
          attachment: attachment,
        ),
      ).thenAnswer((_) async => expected);

      final result = await service.sendGroupAttachment(
        roomId: '!room:example.com',
        attachment: attachment,
      );

      expect(result, same(expected));
      verify(
        () => matrixService.sendAttachment(
          roomId: '!room:example.com',
          attachment: attachment,
        ),
      ).called(1);
      verifyNoMoreInteractions(matrixService);
    });
  });
}
