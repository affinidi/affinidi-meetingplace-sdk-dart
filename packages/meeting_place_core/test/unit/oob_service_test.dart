import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_control_plane/src/core/command/command.dart';
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_stream_manager.dart';
import 'package:meeting_place_core/src/loggers/meeting_place_core_sdk_logger.dart';
import 'package:meeting_place_core/src/meeting_place_core_sdk_error_code.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart'
    as core
    show ContactCard;
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/connection_service.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:meeting_place_core/src/service/identity/model/ephemeral_identity.dart';
import 'package:meeting_place_core/src/service/identity/model/permanent_identity.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
import 'package:meeting_place_core/src/service/oob/oob_service.dart';
import 'package:meeting_place_core/src/service/oob/oob_service_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class MockConnectionManager extends Mock implements ConnectionManager {}

class MockDidManager extends Mock implements DidManager {}

class MockDidDocument extends Mock implements DidDocument {}

class MockWallet extends Mock implements Wallet {}

class MockMediatorService extends Mock implements MediatorService {}

class MockConnectionService extends Mock implements ConnectionService {}

class MockChannelService extends Mock implements ChannelService {}

class MockIdentityService extends Mock implements IdentityService {}

class MockControlPlaneEventStreamManager extends Mock
    implements ControlPlaneEventStreamManager {}

class MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

class FakeDiscoveryCommand<T> extends Fake implements DiscoveryCommand<T> {}

class FakeWallet extends Fake implements Wallet {}

final _testUri = Uri.parse('https://example.com/oob/123');
final _testContactCard = core.ContactCard(
  did: 'did:test:contact',
  type: 'individual',
  contactInfo: const {},
);
const _testMediatorDid = 'did:example:mediator';

class _OobServiceMocks {
  _OobServiceMocks() {
    when(() => acceptOfferDidDoc.id).thenReturn('did:test:accept');
    when(() => permanentChannelDidDoc.id).thenReturn('did:test:permanent');

    when(
      acceptOfferDidManager.getDidDocument,
    ).thenAnswer((_) async => acceptOfferDidDoc);
    when(
      permanentChannelDidManager.getDidDocument,
    ).thenAnswer((_) async => permanentChannelDidDoc);

    when(() => identityService.createEphemeralIdentity(any())).thenAnswer(
      (_) async => EphemeralIdentity(
        didManager: acceptOfferDidManager,
        didDocument: acceptOfferDidDoc,
      ),
    );

    when(
      () => identityService.createPermanentIdentity(any()),
    ).thenAnswer(
      (_) async => PermanentIdentity(
        didManager: permanentChannelDidManager,
        didDocument: permanentChannelDidDoc,
        matrixUserId: '@test:matrix.example.com',
      ),
    );
  }

  final wallet = MockWallet();
  final mediatorService = MockMediatorService();
  final connectionService = MockConnectionService();
  final channelService = MockChannelService();
  final identityService = MockIdentityService();
  final controlPlaneEventStreamManager = MockControlPlaneEventStreamManager();
  final logger = MockLogger();

  final controlPlaneSDK = MockControlPlaneSDK();
  final connectionManager = MockConnectionManager();

  final acceptOfferDidManager = MockDidManager();
  final permanentChannelDidManager = MockDidManager();

  final acceptOfferDidDoc = MockDidDocument();
  final permanentChannelDidDoc = MockDidDocument();

  void stubGetOobThrows(ControlPlaneSDKException exception) {
    when(
      () => controlPlaneSDK.execute<GetOobCommandOutput>(
        any(that: isA<GetOobCommand>()),
      ),
    ).thenThrow(exception);
  }

  OobService buildService() {
    return OobService(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionService: connectionService,
      connectionManager: connectionManager,
      identityService: identityService,
      channelService: channelService,
      controlPlaneSDK: controlPlaneSDK,
      controlPlaneEventStreamManager: controlPlaneEventStreamManager,
      logger: logger,
    );
  }

  Future<void> callAcceptOobFlow(OobService service) async {
    await service.acceptOobFlow(
      _testUri,
      contactCard: _testContactCard,
      mediatorDid: _testMediatorDid,
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDiscoveryCommand<Object?>());
    registerFallbackValue(FakeDiscoveryCommand<GetOobCommandOutput>());
    registerFallbackValue(FakeWallet());
    registerFallbackValue(ChannelTransport.matrix);
  });

  group('OobService', () {
    test('throws invalidOobResponse when ControlPlaneSDKException has unknown '
        'code', () async {
      final exception = ControlPlaneSDKException(
        message: 'Unknown error',
        code: 'some_unknown_code',
        innerException: Exception('inner'),
      );
      final oobServiceMocks = _OobServiceMocks()..stubGetOobThrows(exception);
      final oobService = oobServiceMocks.buildService();

      expect(
        () => oobServiceMocks.callAcceptOobFlow(oobService),
        throwsA(
          isA<OobServiceException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.oobInvalidData,
          ),
        ),
      );
    });

    test(
      'throws networkError when ControlPlaneSDKException is networkError',
      () async {
        final exception = ControlPlaneSDKException(
          message: 'Network error',
          code: ControlPlaneSDKErrorCode.networkError.value,
          innerException: Exception('inner'),
        );
        final oobServiceMocks = _OobServiceMocks()..stubGetOobThrows(exception);
        final oobService = oobServiceMocks.buildService();

        expect(
          () => oobServiceMocks.callAcceptOobFlow(oobService),
          throwsA(
            isA<OobServiceException>().having(
              (e) => e.code,
              'code',
              MeetingPlaceCoreSDKErrorCode.networkError,
            ),
          ),
        );
      },
    );
  });
}
