import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../entity/channel.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../meeting_place_core_sdk_error_code.dart';
import 'matrix_auth_exception.dart';
import 'matrix_call_service.dart';
import 'matrix_config.dart';
import 'matrix_room_event.dart';
import 'matrix_room_service.dart';
import 'matrix_service_exception.dart';
import 'matrix_session_manager.dart';
import 'matrix_subscription_options.dart';
import 'rtc/matrix_rtc_defaults.dart';

/// High-level Matrix facade that orchestrates JWT acquisition and exposes
/// room and MatrixRTC call operations.
///
/// Responsibilities:
/// - Obtaining Matrix JWTs from the control plane via [loginWithDid].
/// - Delegating session lifecycle (client creation, token refresh) to
///   [MatrixSessionManager].
/// - Owning two domain collaborators that transparently re-authenticate when
///   a session has expired: [MatrixRoomService] for room/messaging/media
///   operations and [MatrixCallService] for MatrixRTC call lifecycle.
class MatrixService {
  MatrixService({
    required MatrixConfig config,
    required ControlPlaneSDK controlPlaneSDK,
    required MeetingPlaceCoreSDKLogger logger,
    MatrixSessionManager? sessionManager,
  }) : _controlPlaneSDK = controlPlaneSDK,
       _logger = logger,
       _sessionManager =
           sessionManager ??
           MatrixSessionManager(config: config, logger: logger) {
    _roomService = MatrixRoomService(
      ensureSession: _ensureSession,
      sessionManager: _sessionManager,
    );
    _callService = MatrixCallService(
      ensureSession: _ensureSession,
      logger: _logger,
    );
  }

  /// Control plane SDK for executing commands to obtain Matrix JWTs.
  final ControlPlaneSDK _controlPlaneSDK;

  /// Manages Matrix sessions, including client instances and token refresh.
  final MatrixSessionManager _sessionManager;

  /// Logger for MatrixService operations and errors.
  final MeetingPlaceCoreSDKLogger _logger;

  /// Owns room, messaging, history, and media operations.
  late final MatrixRoomService _roomService;

  /// Owns MatrixRTC / VoIP call lifecycle.
  late final MatrixCallService _callService;

  static const _logKey = 'MatrixService';

  /// Exposes the homeserver URI from the session manager.
  Uri get homeserver => _sessionManager.homeserver;

  /// The Matrix server name used for user ID and room alias derivation.
  ///
  /// In production this equals [homeserver].host. For local development the
  /// homeserver may be reached via a tunnel whose hostname differs from the
  /// Synapse `server_name` — use this instead of [homeserver].host wherever
  /// Matrix identifiers are derived.
  String get serverName => _sessionManager.serverName;

  /// Obtains a Matrix JWT from the control plane for [didManager], logs in,
  /// and returns the Matrix user ID.
  ///
  /// Parameters:
  /// - [didManager]: The DID manager whose DID will be used to obtain the JWT
  ///   and log in to the Matrix homeserver.
  /// - [loginSyncGracePeriod]: How long background sync stays active after
  ///   login before being automatically disabled. Defaults to
  ///   [MatrixSessionManager.loginSyncGracePeriod]. Ignored when
  ///   [keepSyncActiveAfterLogin] is `true`.
  /// - [keepSyncActiveAfterLogin]: When `true`, background sync is never
  ///   automatically disabled after this login — it stays active until
  ///   [dispose] is called.
  ///
  /// Returns: The Matrix user ID associated with the logged-in session.
  Future<String> loginWithDid(
    DidManager didManager, {
    Duration loginSyncGracePeriod = MatrixSessionManager.loginSyncGracePeriod,
    bool keepSyncActiveAfterLogin = false,
  }) async {
    final didDocument = await didManager.getDidDocument();

    final cachedClient = await _sessionManager.getAuthenticatedClient(
      didDocument.id,
    );
    if (cachedClient != null) {
      final userID = cachedClient.userID;
      if (userID == null) {
        throw MatrixServiceException.missingUserId();
      }
      return userID;
    }

    final matrixTokenOutput = await _controlPlaneSDK.execute(
      MatrixTokenCommand(didManager: didManager, homeserver: homeserver),
    );

    _logger.info('Obtained Matrix JWT for ${didDocument.id}', name: _logKey);

    return _sessionManager.loginWithJwt(
      jwt: matrixTokenOutput.token.toJwt(),
      did: didDocument.id,
      loginSyncGracePeriod: loginSyncGracePeriod,
      keepSyncActiveAfterLogin: keepSyncActiveAfterLogin,
    );
  }

  /// Creates a new Matrix room with a deterministic alias derived from the
  /// channel DIDs, optionally inviting specified users.
  ///
  /// See [MatrixRoomService.createRoom].
  Future<String> createRoom({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
    List<String>? inviteUsers,
  }) => _roomService.createRoom(
    didManager: didManager,
    channelDid: channelDid,
    otherPartyChannelDid: otherPartyChannelDid,
    inviteUsers: inviteUsers,
  );

  /// Resolves the deterministic alias for a channel to its Matrix room ID.
  Future<String> resolveChannelRoomId({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
  }) => _roomService.resolveChannelRoomId(
    didManager: didManager,
    channelDid: channelDid,
    otherPartyChannelDid: otherPartyChannelDid,
  );

  /// Resolves the Matrix room ID for [channel].
  ///
  /// See [MatrixRoomService.resolveRoomIdForChannel].
  Future<String> resolveRoomIdForChannel({
    required DidManager didManager,
    required Channel channel,
  }) => _roomService.resolveRoomIdForChannel(
    didManager: didManager,
    channel: channel,
  );

  /// Joins the Matrix room for a channel via its deterministic alias.
  Future<String> joinChannelRoom({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
  }) => _roomService.joinChannelRoom(
    didManager: didManager,
    channelDid: channelDid,
    otherPartyChannelDid: otherPartyChannelDid,
  );

  /// Leaves [roomId]. See [MatrixRoomService.leaveRoom].
  Future<void> leaveRoom(String roomId, {required DidManager didManager}) =>
      _roomService.leaveRoom(roomId, didManager: didManager);

  Future<void> inviteUser(
    String roomId, {
    required String did,
    required DidManager didManager,
  }) => _roomService.inviteUser(roomId, did: did, didManager: didManager);

  /// Removes a member from a Matrix room. See [MatrixRoomService.kickUser].
  Future<void> kickUser(
    String roomId, {
    required String did,
    required DidManager didManager,
  }) => _roomService.kickUser(roomId, did: did, didManager: didManager);

  /// Sends a Matrix room event with [eventType] and [content] to [roomId].
  ///
  /// See [MatrixRoomService.sendRoomEvent].
  Future<String?> sendRoomEvent(
    String roomId,
    String eventType,
    Map<String, dynamic> content, {
    required DidManager didManager,
  }) => _roomService.sendRoomEvent(
    roomId,
    eventType,
    content,
    didManager: didManager,
  );

  /// Returns recent events from [roomId] as [MatrixRoomEvent]s.
  ///
  /// See [MatrixRoomService.fetchRoomHistory].
  Future<List<MatrixRoomEvent>> fetchRoomHistory(
    String roomId, {
    required DidManager didManager,
    int limit = 50,
    String? sinceEventId,
    bool forceSync = false,
  }) => _roomService.fetchRoomHistory(
    roomId,
    didManager: didManager,
    limit: limit,
    sinceEventId: sinceEventId,
    forceSync: forceSync,
  );

  /// Performs a single Matrix sync round-trip for the session associated with
  /// [didManager]. See [MatrixRoomService.oneShotSync].
  Future<void> oneShotSync({required DidManager didManager}) =>
      _roomService.oneShotSync(didManager: didManager);

  /// Returns the most recent event id in [roomId], or `null` if the room is
  /// not known to the client or has no events yet.
  ///
  /// See [MatrixRoomService.getLatestEventId].
  Future<String?> getLatestEventId(
    String roomId, {
    required DidManager didManager,
  }) => _roomService.getLatestEventId(roomId, didManager: didManager);

  /// Returns a stream of [MatrixRoomEvent]s received in [roomId].
  ///
  /// See [MatrixRoomService.subscribeToRoom].
  Stream<MatrixRoomEvent> subscribeToRoom(
    String roomId, {
    required DidManager didManager,
    MatrixSubscriptionOptions options = const MatrixSubscriptionOptions(),
  }) => _roomService.subscribeToRoom(
    roomId,
    didManager: didManager,
    options: options,
  );

  /// Sends a file event with an attachment to [roomId].
  ///
  /// See [MatrixRoomService.sendFileEvent].
  Future<String?> sendFileEvent(
    String roomId, {
    required Uint8List bytes,
    required String contentType,
    required DidManager didManager,
    String? filename,
    Map<String, dynamic>? extraContent,
  }) => _roomService.sendFileEvent(
    roomId,
    bytes: bytes,
    contentType: contentType,
    didManager: didManager,
    filename: filename,
    extraContent: extraContent,
  );

  /// Downloads and decrypts the attachment carried by the message event
  /// [eventId] in [roomId]. See [MatrixRoomService.downloadFileForEvent].
  Future<Uint8List> downloadFileForEvent(
    String roomId,
    String eventId, {
    required DidManager didManager,
  }) => _roomService.downloadFileForEvent(
    roomId,
    eventId,
    didManager: didManager,
  );

  /// Returns the maximum upload size allowed by the homeserver, in bytes.
  /// See [MatrixRoomService.getMediaConfig].
  Future<int?> getMediaConfig({required DidManager didManager}) =>
      _roomService.getMediaConfig(didManager: didManager);

  /// Requests a Matrix OpenID token for [didManager].
  ///
  /// Calls `POST /_matrix/client/v3/user/{userId}/openid/request_token` via
  /// the authenticated Matrix client. The returned [matrix.OpenIdCredentials]
  /// can be passed to lk-jwt-service to obtain a LiveKit JWT without
  /// exposing any server-side secrets to the client.
  ///
  /// Throws [MatrixAuthException] if no active session exists for
  /// [didManager]. Call [loginWithDid] first.
  Future<matrix.OpenIdCredentials> getOpenIdToken(DidManager didManager) async {
    final client = await _ensureSession(didManager);
    final userId = client.userID;
    if (userId == null) {
      throw MatrixServiceException.missingUserId();
    }
    return client.requestOpenIdToken(userId, {});
  }

  // ---------------------------------------------------------------------------
  // MatrixRTC / VoIP
  // ---------------------------------------------------------------------------

  /// Injects the [matrix.VoIP] instance required for MatrixRTC call management.
  ///
  /// See [MatrixCallService.initializeVoIP].
  void initializeVoIP(matrix.VoIP voip) => _callService.initializeVoIP(voip);

  /// Creates a [matrix.VoIP] instance from [delegate] and an authenticated
  /// client for [didManager].
  /// See [MatrixCallService.initializeVoIPWithDelegate].
  Future<void> initializeVoIPWithDelegate({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
  }) => _callService.initializeVoIPWithDelegate(
    didManager: didManager,
    delegate: delegate,
  );

  /// Lazily activates the single Matrix session for [didManager] and resolves
  /// the pending incoming MatrixRTC group call published in [roomId].
  ///
  /// See [MatrixCallService.activateIncomingCall].
  Future<matrix.GroupCallSession> activateIncomingCall({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
    required String roomId,
    Duration timeout = MatrixRtcDefaults.incomingCallActivationTimeout,
  }) => _callService.activateIncomingCall(
    didManager: didManager,
    delegate: delegate,
    roomId: roomId,
    timeout: timeout,
  );

  /// Returns `true` when [roomId] already has at least one non-expired
  /// `m.call.member` state event.
  /// See [MatrixCallService.hasActiveCallMembership].
  Future<bool> hasActiveCallMembership({
    required DidManager didManager,
    required String roomId,
  }) => _callService.hasActiveCallMembership(
    didManager: didManager,
    roomId: roomId,
  );

  /// Returns the callId of the first non-expired MatrixRTC call membership in
  /// [roomId], or `null` when no call is in progress.
  ///
  /// See [MatrixCallService.activeCallId].
  Future<String?> activeCallId({
    required DidManager didManager,
    required String roomId,
  }) => _callService.activeCallId(didManager: didManager, roomId: roomId);

  /// Returns the Matrix participant identity string for the local device.
  ///
  /// The format is `userId:deviceId` (e.g. `@abc:localhost:9000:DEVICEID`).
  /// This value is used as the LiveKit participant identity so that
  /// per-participant E2EE keys can be mapped between Matrix and LiveKit.
  ///
  /// Returns `null` if either the user ID or device ID is unavailable from
  /// the active Matrix session.
  Future<String?> ownMatrixIdentity(DidManager didManager) async {
    final matrix.Client client;
    try {
      client = await _ensureSession(didManager);
    } on MatrixServiceException catch (e) {
      if (e.code == MeetingPlaceCoreSDKErrorCode.matrixMissingUserId) {
        return null;
      }
      rethrow;
    }
    final userId = client.userID;
    final deviceId = client.deviceID;
    if (userId == null || deviceId == null) return null;
    return '$userId:$deviceId';
  }

  /// Returns the Matrix device ID for the active session of [didManager].
  ///
  /// Returns `null` if no active session exists or the device ID is not yet
  /// assigned. Used when requesting a LiveKit JWT from lk-jwt-service so the
  /// participant identity matches the MatrixRTC participant ID format
  /// (`userId:deviceId`).
  Future<String?> getDeviceId(DidManager didManager) async {
    final client = await _ensureSession(didManager);
    return client.deviceID;
  }

  /// Creates or joins a MatrixRTC group call in [roomId] using the LiveKit
  /// SFU backend. See [MatrixCallService.startCall].
  Future<matrix.GroupCallSession> startCall({
    required DidManager didManager,
    required String roomId,
    required String livekitServiceUrl,
    required String livekitAlias,
    String? callId,
  }) => _callService.startCall(
    didManager: didManager,
    roomId: roomId,
    livekitServiceUrl: livekitServiceUrl,
    livekitAlias: livekitAlias,
    callId: callId,
  );

  /// Leaves the active MatrixRTC group call in [roomId] with [callId].
  Future<void> leaveCall({required String roomId, required String callId}) =>
      _callService.leaveCall(roomId: roomId, callId: callId);

  /// Returns a stream of [matrix.MatrixRTCCallEvent]s for the given call.
  ///
  /// See [MatrixCallService.watchCall].
  Stream<matrix.MatrixRTCCallEvent>? watchCall({
    required String roomId,
    required String callId,
  }) => _callService.watchCall(roomId: roomId, callId: callId);

  /// Returns an authenticated client, transparently re-authenticating via
  /// [loginWithDid] when the session has expired or the refresh token is
  /// exhausted.
  Future<matrix.Client> _ensureSession(
    DidManager didManager, {
    bool keepSyncActiveAfterLogin = false,
  }) async {
    final did = (await didManager.getDidDocument()).id;

    await loginWithDid(
      didManager,
      keepSyncActiveAfterLogin: keepSyncActiveAfterLogin,
    );
    final client = await _sessionManager.getAuthenticatedClient(did);
    if (client == null) {
      throw const MatrixAuthException();
    }
    return client;
  }

  /// Disposes the call service subscription and the underlying session
  /// manager, aborting all matrix sync loops and closing each cached client's
  /// database. Safe to call multiple times.
  Future<void> dispose() async {
    await _callService.dispose();
    await _sessionManager.dispose();
  }

  /// Waits until the matrix client owned by [didManager] has converged on
  /// the membership and device-key state needed to encrypt a message that
  /// every DID in [expectedDids] can decrypt.
  ///
  /// See [MatrixRoomService.waitForRoomEncryptionReady]. Intended for test
  /// fixtures only — production code should not need to call it.
  Future<void> waitForRoomEncryptionReady({
    required String roomId,
    required DidManager didManager,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) => _roomService.waitForRoomEncryptionReady(
    roomId: roomId,
    didManager: didManager,
    expectedDids: expectedDids,
    timeout: timeout,
    pollInterval: pollInterval,
  );
}
