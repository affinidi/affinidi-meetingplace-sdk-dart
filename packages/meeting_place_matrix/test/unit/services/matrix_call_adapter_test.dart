import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/entity/group.dart' as core_group;
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/call/call_channel_activity_type.dart';
import 'package:meeting_place_matrix/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_matrix/src/matrix_room_alias.dart';
import 'package:meeting_place_matrix/src/models/sfu_token_response.dart';
import 'package:meeting_place_matrix/src/services/matrix_call_adapter.dart';
import 'package:meeting_place_matrix/src/transport/matrix/matrix_media_attachment.dart';
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

core_group.Group _stubGroup() => core_group.Group(
  id: 'group-id',
  did: 'did:key:group',
  offerLink: 'offer://test',
  status: core_group.GroupStatus.created,
  created: DateTime(2024),
  members: const [],
);

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
      otherPartyContactCard: ContactCard(
        did: _otherPartyDid,
        type: 'individual',
        contactInfo: {'name': 'Other User'},
      ),
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
  Uri? livekitSfuUrl,
  bool useDefaultSfuUrl = true,
  List<String> sfuAllowedHosts = const [],
}) => MatrixCallAdapter(
  matrixService: matrixService,
  coreSDK: coreSDK,
  logger: DefaultMeetingPlaceMatrixSDKLogger(className: 'test'),
  otherPartyChannelDid: _otherPartyDid,
  livekitSfuUrl: useDefaultSfuUrl && livekitSfuUrl == null
      ? Uri.parse(_sfuUrl)
      : livekitSfuUrl,
  sfuAllowedHosts: sfuAllowedHosts,
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
    registerFallbackValue(
      const GroupChannelNotification(
        offerLink: 'offer://fallback',
        groupDid: 'did:key:fallback-group',
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
    when(
      () => coreSDK.getGroupByOfferLink(any()),
    ).thenAnswer((_) async => null);
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

    test(
      'treats the call as group when the offer link belongs to a group',
      () async {
        final channel = _stubChannel(isGroup: false);
        when(
          () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
        ).thenAnswer((_) async => channel);
        when(
          () => coreSDK.getGroupByOfferLink(channel.offerLink),
        ).thenAnswer((_) async => _stubGroup());

        final result = await adapter.resolveChannel();

        expect(
          result.roomName,
          deriveRoomAliasLocalpart(channelDid: _otherPartyDid),
        );
      },
    );
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
      expect(
        result.participantContactCardsByDid.keys,
        containsAll([_ownDid, _otherPartyDid]),
      );
      expect(
        result.participantContactCardsByDid[_otherPartyDid],
        same(channel.otherPartyContactCard),
      );
    });
  });

  group('prepareCallSession', () {
    test('caller reuses the in-progress call id and flags a rejoin', () async {
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

      expect(result.callId, 'existing-call-id');
      expect(result.isRejoin, isTrue);
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

      expect(result.callId, startsWith('$_matrixRoomId@'));
      expect(result.isRejoin, isFalse);
    });
  });

  group('assignFreshCallId', () {
    test('mints a fresh call id and replaces the reused identifier', () async {
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
      ).thenAnswer((_) async => 'ghost-call-id');

      final prepared = await adapter.prepareCallSession(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        isRecipient: false,
      );
      expect(prepared.callId, 'ghost-call-id');

      final fresh = adapter.assignFreshCallId(_matrixRoomId);

      expect(fresh, isNot('ghost-call-id'));
      expect(fresh, startsWith('$_matrixRoomId@'));
      expect(adapter.matrixCallId, fresh);
      expect(adapter.matrixRoomId, _matrixRoomId);
    });
  });

  group('registerMatrixCall and leaveCall', () {
    test('stores identifiers and leaves Matrix call once', () async {
      final didManager = MockDidManager();
      final groupCallSession = MockGroupCallSession();
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
        () => matrixService.leaveCall(
          roomId: _matrixRoomId,
          callId: any(named: 'callId'),
        ),
      ).thenAnswer((_) async {});

      await adapter.prepareCallSession(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        isRecipient: false,
      );
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
        () => matrixService.leaveCall(
          roomId: _matrixRoomId,
          callId: any(named: 'callId'),
        ),
      ).called(1);
      expect(adapter.matrixRoomId, isNull);
      expect(adapter.matrixCallId, isNull);
    });
  });

  group('sendCallCancelToRecipient', () {
    test(
      'sends group decline when the resolved call target is group-backed',
      () async {
        final channel = _stubChannel(isGroup: false);
        when(
          () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
        ).thenAnswer((_) async => channel);
        when(
          () => coreSDK.getGroupByOfferLink(channel.offerLink),
        ).thenAnswer((_) async => _stubGroup());
        when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

        await adapter.resolveChannel();
        unawaited(adapter.sendCallCancelToRecipient());
        await Future<void>.delayed(Duration.zero);

        verify(
          () => coreSDK.notifyChannel(
            any(
              that: isA<GroupChannelNotification>()
                  .having((n) => n.offerLink, 'offerLink', channel.offerLink)
                  .having((n) => n.groupDid, 'groupDid', _otherPartyDid)
                  .having(
                    (n) => n.type,
                    'type',
                    CallChannelActivityType.callDecline,
                  ),
            ),
          ),
        ).called(1);
        verifyNever(
          () => coreSDK.notifyChannel(
            any(that: isA<IndividualChannelNotification>()),
          ),
        );
      },
    );
  });

  group('sendCallInvite', () {
    test('sends individual call invite with requested media type', () async {
      final channel = _stubChannel();

      when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

      await adapter.sendCallInvite(
        channel: channel,
        mediaType: CallMediaType.audio,
      );

      verify(
        () => coreSDK.notifyChannel(
          any(
            that: isA<IndividualChannelNotification>().having(
              (n) => n.type,
              'type',
              CallChannelActivityType.callInviteAudio,
            ),
          ),
        ),
      ).called(1);
      verifyNever(
        () => matrixService.sendRoomEvent(
          any(),
          any(),
          any(),
          didManager: any(named: 'didManager'),
        ),
      );
    });
  });

  group('sendCallOutcome', () {
    Future<void> primeRoom() async {
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
      await adapter.prepareCallSession(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        isRecipient: false,
      );
    }

    test('posts an ended outcome room event carrying the callId', () async {
      await primeRoom();
      final channel = _stubChannel();
      final didManager = MockDidManager();
      final startedAt = DateTime.utc(2026, 1, 1, 12);

      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
      ).thenAnswer((_) async => channel);
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

      await adapter.sendCallOutcome(callId: 'call-42', startedAt: startedAt);

      final captured = verify(
        () => matrixService.sendRoomEvent(
          _matrixRoomId,
          captureAny(),
          captureAny(),
          didManager: any(named: 'didManager'),
        ),
      ).captured;
      expect(captured[0], MpxCallEventType.callOutcome);
      final content = captured[1] as Map<String, dynamic>;
      final record = content[MatrixEventField.callOutcome] as Map;
      expect(record['call_id'], 'call-42');
      expect(record['outcome'], CallOutcome.ended.name);
    });

    test('does nothing when no active room is set', () async {
      await adapter.sendCallOutcome(callId: 'call-42');

      verifyNever(
        () => matrixService.sendRoomEvent(
          any(),
          any(),
          any(),
          didManager: any(named: 'didManager'),
        ),
      );
    });
  });

  group('SFU URL validation (SEC fix)', () {
    test('accepts explicit wss:// URL in dev mode without allowlist', () async {
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
        (_) async => const SfuTokenResponse(
          token: _sfuToken,
          url: null, // server returns no URL
        ),
      );

      // Dev mode: explicit livekitSfuUrl, empty allowlist is OK
      final adapterDevMode = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        livekitSfuUrl: Uri.parse('wss://dev.example.com'),
        sfuAllowedHosts: [],
      );

      final result = await adapterDevMode.fetchCallCredentials(
        channel: channel,
        ownChannelDid: _ownDid,
        roomName: _roomName,
      );

      expect(result.sfuUrl, 'wss://dev.example.com');
    });

    test(
      'accepts explicit ws:// URL in dev mode (local Docker development)',
      () async {
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

        // Dev mode: app-supplied ws:// URL (e.g. container-internal hostname)
        // is permitted because the application controls the value; it cannot
        // be tampered with by a compromised JWT service.
        final adapterDevWs = _buildAdapter(
          coreSDK: coreSDK,
          matrixService: matrixService,
          tokenService: tokenService,
          livekitSfuUrl: Uri.parse('ws://livekit:7880'),
          sfuAllowedHosts: [],
        );

        final result = await adapterDevWs.fetchCallCredentials(
          channel: channel,
          ownChannelDid: _ownDid,
          roomName: _roomName,
        );

        expect(result.sfuUrl, 'ws://livekit:7880');
      },
    );

    test('accepts wss:// URL matching exact host in allowlist', () async {
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
        (_) async => const SfuTokenResponse(
          token: _sfuToken,
          url: 'wss://allowed.example.com',
        ),
      );

      final adapterWithAllowlist = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        useDefaultSfuUrl: false,
        sfuAllowedHosts: ['allowed.example.com', 'other.example.com'],
      );

      final result = await adapterWithAllowlist.fetchCallCredentials(
        channel: channel,
        ownChannelDid: _ownDid,
        roomName: _roomName,
      );

      expect(result.sfuUrl, 'wss://allowed.example.com');
    });

    test('accepts wss:// URL matching wildcard pattern in allowlist', () async {
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
        (_) async => const SfuTokenResponse(
          token: _sfuToken,
          url: 'wss://livekit.meetingplace.affinidi.io',
        ),
      );

      final adapterWildcard = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        useDefaultSfuUrl: false,
        sfuAllowedHosts: ['*.meetingplace.affinidi.io'],
      );

      final result = await adapterWildcard.fetchCallCredentials(
        channel: channel,
        ownChannelDid: _ownDid,
        roomName: _roomName,
      );

      expect(result.sfuUrl, 'wss://livekit.meetingplace.affinidi.io');
    });

    test(
      'rejects deeper subdomain not covered by single-label wildcard',
      () async {
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
          (_) async => const SfuTokenResponse(
            token: _sfuToken,
            // Deeper subdomain: `*.meetingplace.affinidi.io` must NOT match.
            url: 'wss://evil.sub.meetingplace.affinidi.io',
          ),
        );

        final adapterWildcard = _buildAdapter(
          coreSDK: coreSDK,
          matrixService: matrixService,
          tokenService: tokenService,
          useDefaultSfuUrl: false,
          sfuAllowedHosts: ['*.meetingplace.affinidi.io'],
        );

        expect(
          () => adapterWildcard.fetchCallCredentials(
            channel: channel,
            ownChannelDid: _ownDid,
            roomName: _roomName,
          ),
          throwsA(
            isA<MeetingPlaceLiveKitCallOperationException>().having(
              (e) => e.message,
              'message',
              contains(
                'SFU host "evil.sub.meetingplace.affinidi.io" is not in the '
                'allowlist',
              ),
            ),
          ),
        );
      },
    );

    test('rejects ws:// URL (non-TLS)', () async {
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
        (_) async => const SfuTokenResponse(
          token: _sfuToken,
          url: 'ws://evil.example.com', // cleartext WebSocket
        ),
      );

      final adapterNoTls = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        useDefaultSfuUrl: false,
      );

      expect(
        () => adapterNoTls.fetchCallCredentials(
          channel: channel,
          ownChannelDid: _ownDid,
          roomName: _roomName,
        ),
        throwsA(
          isA<MeetingPlaceLiveKitCallOperationException>().having(
            (e) => e.message,
            'message',
            contains('SFU URL must use wss:// scheme, got: ws'),
          ),
        ),
      );
    });

    test('rejects https:// URL (wrong scheme)', () async {
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
        (_) async => const SfuTokenResponse(
          token: _sfuToken,
          url: 'https://evil.example.com', // HTTPS instead of WSS
        ),
      );

      final adapterHttps = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        useDefaultSfuUrl: false,
      );

      expect(
        () => adapterHttps.fetchCallCredentials(
          channel: channel,
          ownChannelDid: _ownDid,
          roomName: _roomName,
        ),
        throwsA(
          isA<MeetingPlaceLiveKitCallOperationException>().having(
            (e) => e.message,
            'message',
            contains('SFU URL must use wss:// scheme, got: https'),
          ),
        ),
      );
    });

    test('rejects URL when host not in allowlist', () async {
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
        (_) async => const SfuTokenResponse(
          token: _sfuToken,
          url: 'wss://attacker.example.com',
        ),
      );

      final adapterRestricted = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        useDefaultSfuUrl: false,
        sfuAllowedHosts: ['allowed.example.com', '*.trusted.io'],
      );

      expect(
        () => adapterRestricted.fetchCallCredentials(
          channel: channel,
          ownChannelDid: _ownDid,
          roomName: _roomName,
        ),
        throwsA(
          isA<MeetingPlaceLiveKitCallOperationException>().having(
            (e) => e.message,
            'message',
            contains('SFU host "attacker.example.com" is not in the allowlist'),
          ),
        ),
      );
    });

    test('rejects null/empty URL', () async {
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

      final adapterNoUrl = _buildAdapter(
        coreSDK: coreSDK,
        matrixService: matrixService,
        tokenService: tokenService,
        useDefaultSfuUrl: false,
      );

      expect(
        () => adapterNoUrl.fetchCallCredentials(
          channel: channel,
          ownChannelDid: _ownDid,
          roomName: _roomName,
        ),
        throwsA(
          isA<MeetingPlaceLiveKitCallOperationException>().having(
            (e) => e.message,
            'message',
            contains('No LiveKit SFU URL available'),
          ),
        ),
      );
    });

    test(
      'rejects server-supplied URL without allowlist (production security)',
      () async {
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
          (_) async => const SfuTokenResponse(
            token: _sfuToken,
            url: 'wss://valid-server.example.com',
          ),
        );

        // Production mode: livekitSfuUrl is null, sfuAllowedHosts is empty
        final adapterProductionNoAllowlist = _buildAdapter(
          coreSDK: coreSDK,
          matrixService: matrixService,
          tokenService: tokenService,
          useDefaultSfuUrl: false, // server-supplied URL
          sfuAllowedHosts: [], // empty allowlist = security violation
        );

        expect(
          () => adapterProductionNoAllowlist.fetchCallCredentials(
            channel: channel,
            ownChannelDid: _ownDid,
            roomName: _roomName,
          ),
          throwsA(
            isA<MeetingPlaceLiveKitCallOperationException>().having(
              (e) => e.message,
              'message',
              allOf([
                contains('Security violation'),
                contains('sfuAllowedHosts must be configured'),
              ]),
            ),
          ),
        );
      },
    );
  });

  group('sendCallCancelToRecipient', () {
    test('sends individual decline notification for direct calls', () async {
      final channel = _stubChannel();
      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
      ).thenAnswer((_) async => channel);
      when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

      await adapter.resolveChannel();
      await adapter.sendCallCancelToRecipient();

      verify(
        () => coreSDK.notifyChannel(
          any(
            that: isA<IndividualChannelNotification>()
                .having(
                  (notification) => notification.recipientDid,
                  'recipientDid',
                  _otherPartyDid,
                )
                .having(
                  (notification) => notification.type,
                  'type',
                  CallChannelActivityType.callDecline,
                ),
          ),
        ),
      ).called(1);
    });

    test('sends group decline notification for group calls', () async {
      final channel = _stubChannel(isGroup: true);
      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
      ).thenAnswer((_) async => channel);
      when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

      await adapter.resolveChannel();
      await adapter.sendCallCancelToRecipient();

      verify(
        () => coreSDK.notifyChannel(
          any(
            that: isA<GroupChannelNotification>()
                .having(
                  (notification) => notification.offerLink,
                  'offerLink',
                  'offer://test',
                )
                .having(
                  (notification) => notification.groupDid,
                  'groupDid',
                  _otherPartyDid,
                )
                .having(
                  (notification) => notification.type,
                  'type',
                  CallChannelActivityType.callDecline,
                ),
          ),
        ),
      ).called(1);
    });

    test('sends active group cancel through the Matrix room event', () async {
      final channel = _stubChannel(isGroup: true);
      final didManager = MockDidManager();
      final groupCallSession = MockGroupCallSession();
      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
      ).thenAnswer((_) async => channel);
      when(
        () => coreSDK.getDidManager(_ownDid),
      ).thenAnswer((_) async => didManager);
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
        () => matrixService.sendRoomEvent(
          _matrixRoomId,
          MpxCallEventType.callCancel,
          any(),
          didManager: didManager,
        ),
      ).thenAnswer((_) async => 'cancel-event-id');
      when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

      await adapter.resolveChannel();
      await adapter.prepareCallSession(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        isRecipient: false,
      );
      await adapter.registerMatrixCall(
        didManager: didManager,
        matrixRoomId: _matrixRoomId,
        callId: 'call-id',
        sfuUrl: _sfuUrl,
        roomName: _roomName,
      );
      await adapter.sendCallCancelToRecipient();

      verify(
        () => matrixService.sendRoomEvent(
          _matrixRoomId,
          MpxCallEventType.callCancel,
          any(),
          didManager: didManager,
        ),
      ).called(1);
      verify(
        () => coreSDK.notifyChannel(
          any(
            that: isA<GroupChannelNotification>().having(
              (notification) => notification.type,
              'type',
              CallChannelActivityType.callDecline,
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'skip extra channel lookup after resolveChannel primed cancel',
      () async {
        final channel = _stubChannel(isGroup: true);
        when(
          () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
        ).thenAnswer((_) async => channel);
        when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

        await adapter.resolveChannel();
        clearInteractions(coreSDK);

        await adapter.sendCallCancelToRecipient();

        verify(() => coreSDK.notifyChannel(any())).called(1);
        verifyNever(() => coreSDK.getChannelByOtherPartyPermanentDid(any()));
      },
    );

    test(
      'resolves group decline target before resolveChannel completes',
      () async {
        final channel = _stubChannel(isGroup: false);
        when(
          () => coreSDK.getChannelByOtherPartyPermanentDid(_otherPartyDid),
        ).thenAnswer((_) async => channel);
        when(
          () => coreSDK.getGroupByOfferLink(channel.offerLink),
        ).thenAnswer((_) async => _stubGroup());
        when(() => coreSDK.notifyChannel(any())).thenAnswer((_) async {});

        await adapter.sendCallCancelToRecipient();

        verify(
          () =>
              coreSDK.notifyChannel(any(that: isA<GroupChannelNotification>())),
        ).called(1);
      },
    );
  });
}
