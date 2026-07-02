import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/matrix_room_alias.dart';
import 'package:meeting_place_matrix/src/models/sfu_token_response.dart';
import 'package:meeting_place_matrix/src/services/matrix_call_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fakes/fake_fallbacks.dart';
import '../mocks/mocks.dart';

const _otherPartyDid = 'did:key:other-party';
const _ownDid = 'did:key:own';
const _matrixRoomId = '!room:matrix.test';
const _roomName = 'livekit-room';
const _sfuToken = 'livekit-jwt';
const _sfuUrl = 'wss://livekit.test';

Channel _stubChannel({bool isGroup = false, String? permanentChannelDid}) =>
    Channel(
      offerLink: 'offer://test',
      publishOfferDid: _ownDid,
      mediatorDid: 'did:key:mediator',
      status: ChannelStatus.inaugurated,
      contactCard: ContactCard(
        did: _ownDid,
        type: isGroup ? 'group' : 'individual',
        contactInfo: {'name': 'Test User'},
      ),
      type: isGroup ? ChannelType.group : ChannelType.individual,
      transport: ChannelTransport.matrix,
      isConnectionInitiator: true,
      permanentChannelDid: permanentChannelDid ?? _ownDid,
      otherPartyPermanentChannelDid: _otherPartyDid,
    );

OpenIdCredentials _stubOpenIdCredentials() => OpenIdCredentials(
  accessToken: 'matrix-openid-token',
  expiresIn: 3600,
  matrixServerName: 'matrix.test',
  tokenType: 'Bearer',
);

MatrixCallAdapter _buildAdapter({
  required MockMatrixService matrixService,
  required MockMeetingPlaceCoreSDK coreSDK,
  required MockSfuTokenService tokenService,
}) => MatrixCallAdapter(
  matrixService: matrixService,
  coreSDK: coreSDK,
  logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
  otherPartyChannelDid: _otherPartyDid,
  livekitSfuUrl: Uri.parse(_sfuUrl),
  livekitTokenService: tokenService,
  rtcDelegate: MockWebRTCDelegate(),
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDidManager());
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakeOutgoingMessage());
    registerFallbackValue(FakeOpenIdCredentials());
    registerFallbackValue(FakeWebRTCDelegate());
    registerFallbackValue(
      const IndividualChannelNotification(
        recipientDid: 'did:key:fallback',
        type: CallChannelActivityType.callDecline,
      ),
    );
  });

  late MockMatrixService matrixService;
  late MockMeetingPlaceCoreSDK coreSDK;
  late MockSfuTokenService tokenService;
  late MatrixCallAdapter adapter;

  setUp(() {
    matrixService = MockMatrixService();
    coreSDK = MockMeetingPlaceCoreSDK();
    tokenService = MockSfuTokenService();
    adapter = _buildAdapter(
      matrixService: matrixService,
      coreSDK: coreSDK,
      tokenService: tokenService,
    );
  });

  group('resolveChannel', () {
    test(
      'returns resolved individual channel, own DID, and room name',
      () async {
        final channel = _stubChannel();
        when(
          () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
        ).thenAnswer((_) async => channel);

        final result = await adapter.resolveChannel();

        expect(result.channel, same(channel));
        expect(result.ownChannelDid, _ownDid);
        expect(
          result.roomName,
          deriveRoomAliasLocalpart(
            channelDid: _ownDid,
            otherPartyChannelDid: _otherPartyDid,
          ),
        );
      },
    );

    test('throws operation exception when channel is missing', () async {
      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
      ).thenAnswer((_) async => null);

      expect(
        adapter.resolveChannel,
        throwsA(isA<MeetingPlaceLiveKitCallOperationException>()),
      );
    });
  });

  group('fetchCallCredentials', () {
    test('resolves Matrix credentials, participant map, and token', () async {
      final channel = _stubChannel();
      final didManager = MockDidManager();
      when(
        () => coreSDK.getDidManager(_ownDid),
      ).thenAnswer((_) async => didManager);
      when(
        () => matrixService.resolveRoomIdForChannel(
          didManager: didManager,
          channel: channel,
        ),
      ).thenAnswer((_) async => _matrixRoomId);
      when(
        () => matrixService.getOpenIdToken(didManager),
      ).thenAnswer((_) async => _stubOpenIdCredentials());
      when(
        () => matrixService.getDeviceId(didManager),
      ).thenAnswer((_) async => 'DEVICE1');
      when(
        () => tokenService.fetchToken(
          roomName: _roomName,
          openIdCredentials: any(named: 'openIdCredentials'),
          deviceId: 'DEVICE1',
        ),
      ).thenAnswer(
        (_) async => const SfuTokenResponse(token: _sfuToken, url: null),
      );

      final result = await adapter.fetchCallCredentials(
        channel: channel,
        ownChannelDid: _ownDid,
        roomName: _roomName,
      );

      expect(result.didManager, same(didManager));
      expect(result.matrixRoomId, _matrixRoomId);
      expect(result.sfuUrl, _sfuUrl);
      expect(result.sfuToken, _sfuToken);
      expect(
        result.participantIdToDid.values,
        containsAll([_ownDid, _otherPartyDid]),
      );
    });
  });

  group('prepareCallSession', () {
    test('uses existing call id when Matrix reports an active call', () async {
      final didManager = MockDidManager();
      when(
        () => matrixService.initializeVoIPWithDelegate(
          didManager: didManager,
          delegate: any(named: 'delegate'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => matrixService.activeCallId(
          didManager: didManager,
          roomId: _matrixRoomId,
        ),
      ).thenAnswer((_) async => 'existing-call-id');

      final result = await adapter.prepareCallSession(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        isRecipient: false,
      );

      expect(result.callAlreadyInProgress, isTrue);
      expect(result.callId, 'existing-call-id');
    });

    test('generates a new call id when no active call exists', () async {
      final didManager = MockDidManager();
      when(
        () => matrixService.initializeVoIPWithDelegate(
          didManager: didManager,
          delegate: any(named: 'delegate'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => matrixService.activeCallId(
          didManager: didManager,
          roomId: _matrixRoomId,
        ),
      ).thenAnswer((_) async => null);

      final result = await adapter.prepareCallSession(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        isRecipient: false,
      );

      expect(result.callAlreadyInProgress, isFalse);
      expect(result.callId, startsWith('$_matrixRoomId@'));
    });
  });

  group('registerMatrixCall and leaveCall', () {
    test('stores identifiers and leaves Matrix call once', () async {
      final didManager = MockDidManager();
      final groupCallSession = MockGroupCallSession();
      when(
        () => matrixService.startCall(
          didManager: didManager,
          roomId: _matrixRoomId,
          callId: 'call-id',
          livekitServiceUrl: _sfuUrl,
          livekitAlias: _roomName,
        ),
      ).thenAnswer((_) async => groupCallSession);
      when(
        () => matrixService.leaveCall(roomId: _matrixRoomId, callId: 'call-id'),
      ).thenAnswer((_) async {});

      await adapter.registerMatrixCall(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        callId: 'call-id',
        sfuUrl: _sfuUrl,
        roomName: _roomName,
      );
      await adapter.leaveCall();
      await adapter.leaveCall();

      verify(
        () => matrixService.leaveCall(roomId: _matrixRoomId, callId: 'call-id'),
      ).called(1);
      expect(adapter.matrixRoomId, isNull);
      expect(adapter.matrixCallId, isNull);
    });
  });

  group('sendCallInvite', () {
    test('sends individual call invite with requested media type', () async {
      final channel = _stubChannel();
      final didManager = MockDidManager();

      when(
        () => coreSDK.getDidManager(_ownDid),
      ).thenAnswer((_) async => didManager);
      when(
        () => matrixService.sendRoomEvent(
          _matrixRoomId,
          any(),
          any(),
          didManager: any(named: 'didManager'),
        ),
      ).thenAnswer((_) async => 'event-id');
      when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

      await adapter.sendCallInvite(
        channel: channel,
        callAlreadyInProgress: false,
        matrixRoomId: _matrixRoomId,
        mediaType: CallMediaType.audio,
      );

      verify(
        () => matrixService.sendRoomEvent(
          _matrixRoomId,
          any(),
          any(),
          didManager: any(named: 'didManager'),
        ),
      ).called(1);
    });

    test('does not send invite when rejoining an in-progress call', () async {
      await adapter.sendCallInvite(
        channel: _stubChannel(),
        callAlreadyInProgress: true,
        matrixRoomId: _matrixRoomId,
      );

      verifyNever(
        () => matrixService.sendRoomEvent(
          any(),
          any(),
          any(),
          didManager: any(named: 'didManager'),
        ),
      );
      verifyNever(() => coreSDK.notifyChannel(any()));
    });
  });
}
