import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix_livekit/src/exceptions/meeting_place_livekit_call_exception.dart';
import 'package:meeting_place_matrix_livekit/src/models/sfu_token_response.dart';
import 'package:meeting_place_matrix_livekit/src/services/matrix_call_adapter.dart';
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
  required MockMeetingPlaceCoreSDK sdk,
  required MockSfuTokenService tokenService,
}) => MatrixCallAdapter(
  sdk: sdk,
  logger: DefaultMeetingPlaceCoreSDKLogger(className: 'test'),
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
  });

  late MockMeetingPlaceCoreSDK sdk;
  late MockSfuTokenService tokenService;
  late MatrixCallAdapter adapter;

  setUp(() {
    sdk = MockMeetingPlaceCoreSDK();
    tokenService = MockSfuTokenService();
    adapter = _buildAdapter(sdk: sdk, tokenService: tokenService);
  });

  group('resolveChannel', () {
    test(
      'returns resolved individual channel, own DID, and room name',
      () async {
        final channel = _stubChannel();
        when(
          () => sdk.getChannelByOtherPartyPermanentDid(_otherPartyDid),
        ).thenAnswer((_) async => channel);
        when(
          () => sdk.livekitRoomName(
            channelDid: _ownDid,
            otherPartyChannelDid: _otherPartyDid,
          ),
        ).thenReturn(_roomName);

        final result = await adapter.resolveChannel();

        expect(result.channel, same(channel));
        expect(result.ownChannelDid, _ownDid);
        expect(result.roomName, _roomName);
      },
    );

    test('throws operation exception when channel is missing', () async {
      when(
        () => sdk.getChannelByOtherPartyPermanentDid(_otherPartyDid),
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
        () => sdk.getDidManager(_ownDid),
      ).thenAnswer((_) async => didManager);
      when(
        () => sdk.resolveMatrixRoomIdForChannel(
          didManager: didManager,
          channel: channel,
        ),
      ).thenAnswer((_) async => _matrixRoomId);
      when(
        () => sdk.getMatrixOpenIdToken(didManager),
      ).thenAnswer((_) async => _stubOpenIdCredentials());
      when(
        () => sdk.getMatrixDeviceId(didManager),
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
        () => sdk.initializeMatrixRTCWithDelegate(
          didManager: didManager,
          delegate: any(named: 'delegate'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => sdk.activeVideoCallId(
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
        () => sdk.initializeMatrixRTCWithDelegate(
          didManager: didManager,
          delegate: any(named: 'delegate'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => sdk.activeVideoCallId(
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
        () => sdk.startVideoCall(
          didManager: didManager,
          roomId: _matrixRoomId,
          callId: 'call-id',
          livekitServiceUrl: _sfuUrl,
          livekitAlias: _roomName,
        ),
      ).thenAnswer((_) async => groupCallSession);
      when(
        () => sdk.leaveVideoCall(roomId: _matrixRoomId, callId: 'call-id'),
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
        () => sdk.leaveVideoCall(roomId: _matrixRoomId, callId: 'call-id'),
      ).called(1);
      expect(adapter.matrixRoomId, isNull);
      expect(adapter.matrixCallId, isNull);
    });
  });

  group('sendCallInvite', () {
    test('sends individual call invite with requested media type', () async {
      final channel = _stubChannel();
      when(() => sdk.sendMessage(any())).thenAnswer((_) async => null);

      await adapter.sendCallInvite(
        channel: channel,
        callAlreadyInProgress: false,
        mediaType: CallMediaType.audio,
      );

      verify(() => sdk.sendMessage(any())).called(1);
    });

    test('does not send invite when rejoining an in-progress call', () async {
      await adapter.sendCallInvite(
        channel: _stubChannel(),
        callAlreadyInProgress: true,
      );

      verifyNever(() => sdk.sendMessage(any()));
    });
  });
}
