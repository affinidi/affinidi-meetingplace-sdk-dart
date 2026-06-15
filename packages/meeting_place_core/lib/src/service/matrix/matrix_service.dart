import 'dart:async';
import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../entity/channel.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../meeting_place_core_sdk_error_code.dart';
import 'matrix_auth_exception.dart';
import 'matrix_config.dart';
import 'matrix_room_alias.dart';
import 'matrix_room_event.dart';
import 'matrix_service_exception.dart';
import 'matrix_session_manager.dart';
import 'matrix_subscription_options.dart';
import 'rtc/matrix_rtc_call_scope.dart';
import 'rtc/matrix_rtc_call_type.dart';
import 'rtc/matrix_rtc_defaults.dart';

/// High-level Matrix service that orchestrates JWT acquisition and room
/// operations.
///
/// Responsibilities:
/// - Obtaining Matrix JWTs from the control plane via [loginWithDid].
/// - Delegating session lifecycle (client creation, token refresh) to
///   [MatrixSessionManager].
/// - Exposing room operations ([createRoom], `joinRoom`) that transparently
///   re-authenticate when a session has expired.
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
           MatrixSessionManager(config: config, logger: logger);

  /// Control plane SDK for executing commands to obtain Matrix JWTs.
  final ControlPlaneSDK _controlPlaneSDK;

  /// Manages Matrix sessions, including client instances and token refresh.
  final MatrixSessionManager _sessionManager;

  /// Logger for MatrixService operations and errors.
  final MeetingPlaceCoreSDKLogger _logger;

  static const _logKey = 'MatrixService';

  /// VoIP instance for MatrixRTC call management. Set via [initializeVoIP]
  /// or [initializeVoIPWithDelegate] before calling [startCall].
  matrix.VoIP? _voip;

  /// The VoIP instance whose [matrix.VoIP.onIncomingGroupCall] stream is
  /// currently subscribed.
  ///
  /// That stream is single-subscription, so the service listens to it exactly
  /// once per VoIP instance (see [_ensureIncomingGroupCallListener]) rather
  /// than re-listening on every [activateIncomingCall] call.
  matrix.VoIP? _incomingCallListenerVoip;

  /// Subscription to [matrix.VoIP.onIncomingGroupCall] for the VoIP instance
  /// referenced by [_incomingCallListenerVoip].
  StreamSubscription<matrix.GroupCallSession>? _incomingGroupCallSubscription;

  /// In-flight [activateIncomingCall] requests waiting for their group call to
  /// surface in room state.
  final List<({String roomId, Completer<matrix.GroupCallSession> completer})>
  _pendingActivations = [];

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
  ///
  /// Returns: The Matrix user ID associated with the logged-in session.
  Future<String> loginWithDid(DidManager didManager) async {
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
    );
  }

  /// Creates a new Matrix room with a deterministic alias derived from the
  /// channel DIDs, optionally inviting specified users.
  ///
  /// For two-party channels (individual, OOB) pass both [channelDid] and
  /// [otherPartyChannelDid]; for group channels pass only [channelDid].
  /// See [deriveRoomAliasLocalpart] for the localpart semantics.
  ///
  /// Returns: The ID of the newly created Matrix room.
  Future<String> createRoom({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
    List<String>? inviteUsers,
  }) async {
    final client = await _ensureSession(didManager);
    if (!client.encryptionEnabled) {
      throw MatrixServiceException.encryptionNotEnabled();
    }
    return client.createRoom(
      roomAliasName: deriveRoomAliasLocalpart(
        channelDid: channelDid,
        otherPartyChannelDid: otherPartyChannelDid,
      ),
      invite: inviteUsers
          ?.map((did) => _sessionManager.deriveUserId(did, serverName))
          .toList(),
      initialState: [
        matrix.StateEvent(
          type: matrix.EventTypes.Encryption,
          content: {
            'algorithm': matrix.Client.supportedGroupEncryptionAlgorithms.first,
          },
        ),
      ],
    );
  }

  /// Resolves the deterministic alias for a channel to its Matrix room ID.
  Future<String> resolveChannelRoomId({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
  }) async {
    final client = await _ensureSession(didManager);
    final alias = deriveRoomAlias(
      channelDid: channelDid,
      otherPartyChannelDid: otherPartyChannelDid,
      homeserverHost: serverName,
    );
    final response = await client.getRoomIdByAlias(alias);
    final roomId = response.roomId;
    if (roomId == null) {
      throw StateError('Matrix alias $alias did not resolve to a room id');
    }
    return roomId;
  }

  /// Resolves the Matrix room ID for [channel].
  ///
  /// Uses [Channel.matrixRoomId] when available (set at inauguration time) so
  /// that the lookup works without alias registration. Falls back to alias
  /// derivation for channels inaugurated before this field was introduced.
  Future<String> resolveRoomIdForChannel({
    required DidManager didManager,
    required Channel channel,
  }) {
    if (channel.matrixRoomId != null) {
      return Future.value(channel.matrixRoomId);
    }
    if (channel.type == ChannelType.group) {
      return resolveChannelRoomId(
        didManager: didManager,
        channelDid: channel.otherPartyPermanentChannelDid!,
      );
    }
    return resolveChannelRoomId(
      didManager: didManager,
      channelDid: channel.permanentChannelDid!,
      otherPartyChannelDid: channel.otherPartyPermanentChannelDid,
    );
  }

  /// Joins the Matrix room for a channel via its deterministic alias.
  Future<String> joinChannelRoom({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
  }) async {
    final client = await _ensureSession(didManager);
    final roomId = await client.joinRoom(
      deriveRoomAlias(
        channelDid: channelDid,
        otherPartyChannelDid: otherPartyChannelDid,
        homeserverHost: serverName,
      ),
    );
    var room = client.getRoomById(roomId);
    if (room == null) {
      await client.waitForRoomInSync(roomId, join: true);
      room = client.getRoomById(roomId);
    }
    if (room == null) {
      throw StateError(
        'Matrix room $roomId did not appear after joining; '
        'cannot verify end-to-end encryption state.',
      );
    }
    _assertRoomEncrypted(room, roomId);
    return roomId;
  }

  /// Leaves [roomId]. No-op when the local user is no longer a participant
  /// (e.g. previously kicked or already left), so callers cleaning up after a
  /// remote-initiated removal can invoke it safely.
  Future<void> leaveRoom(
    String roomId, {
    required DidManager didManager,
  }) async {
    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) return;

    if (_isAlreadyOutOfRoom(room, client.userID)) return;
    await client.leaveRoom(roomId);
  }

  Future<void> inviteUser(
    String roomId, {
    required String did,
    required DidManager didManager,
  }) async {
    final client = await _ensureSession(didManager);
    final userId = _sessionManager.deriveUserId(did, serverName);
    await client.inviteUser(roomId, userId);
  }

  /// Removes a member from a Matrix room by deriving their user ID from
  /// [did] and calling `room.kick`. No-op when the target is already not a
  /// participant (membership `leave` or `ban`), so the call is safe to retry
  /// after a previous kick.
  ///
  /// The caller (identified by [didManager]) must have power-level permission
  /// to kick in [roomId]; otherwise the underlying Matrix call will fail.
  Future<void> kickUser(
    String roomId, {
    required String did,
    required DidManager didManager,
  }) async {
    final client = await _ensureSession(didManager);
    final userId = _sessionManager.deriveUserId(did, serverName);
    final room = client.getRoomById(roomId);
    if (room == null) {
      throw StateError('Matrix room $roomId not found');
    }
    if (_isAlreadyOutOfRoom(room, userId)) return;
    await room.kick(userId);
  }

  /// Returns whether [userId] is no longer a participant in [room] — i.e.
  /// their last membership state is `leave` or `ban`. Used to make
  /// membership-mutating calls (`leave`, `kick`) idempotent.
  static bool _isAlreadyOutOfRoom(matrix.Room room, String? userId) {
    if (userId == null) return false;
    final memberState = room.getState(matrix.EventTypes.RoomMember, userId);
    final membership = memberState?.content['membership'] as String?;

    return membership == matrix.Membership.leave.name ||
        membership == matrix.Membership.ban.name;
  }

  /// Sends a Matrix room event with [eventType] and [content] to [roomId].
  ///
  /// Parameters:
  /// - [roomId]: The ID of the Matrix room to send the event to.
  /// - [eventType]: The Matrix event type (a ChatProtocol URI).
  /// - [content]: The event content payload.
  /// - [didManager]: The DID manager used to ensure an authenticated session.
  Future<String?> sendRoomEvent(
    String roomId,
    String eventType,
    Map<String, dynamic> content, {
    required DidManager didManager,
  }) async {
    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) throw StateError('Matrix room $roomId not found');
    _assertRoomEncrypted(room, roomId);

    if (eventType == 'm.read') {
      final eventId = content['event_id'] as String;
      await room.setReadMarker(eventId, mRead: eventId);
      return null;
    }

    if (eventType == 'm.room.redaction') {
      final targetEventId = content['redacts'] as String;
      await room.redactEvent(targetEventId);
      return null;
    }

    if (eventType == 'm.typing') {
      final active = content['active'] as bool;
      final timeoutMs = content['timeoutMs'] as int?;
      await room.setTyping(active, timeout: active ? timeoutMs : null);
      return null;
    }

    return room.sendEvent(content, type: eventType);
  }

  /// Returns recent events from [roomId] as [MatrixRoomEvent]s.
  ///
  /// Parameters:
  /// - [roomId]: The ID of the Matrix room to fetch history from.
  /// - [didManager]: The DID manager used to ensure an authenticated session.
  /// - [limit]: Maximum number of events to return (default: 50).
  /// - [sinceEventId]: When non-null, stops walking the timeline at this
  ///   event id (exclusive), so only events strictly newer than the marker
  ///   are returned.
  Future<List<MatrixRoomEvent>> fetchRoomHistory(
    String roomId, {
    required DidManager didManager,
    int limit = 50,
    String? sinceEventId,
  }) async {
    final client = await _ensureSession(didManager);
    final myUserId = _sessionManager.deriveUserId(
      (await didManager.getDidDocument()).id,
      serverName,
    );
    final room = client.getRoomById(roomId);
    if (room == null) return [];

    final timeline = await room.getTimeline(limit: limit);

    if (timeline.events.length < limit && timeline.canRequestHistory) {
      await timeline.requestHistory(historyCount: limit);
    }

    final events = timeline.events
        .takeWhile((e) => sinceEventId == null || e.eventId != sinceEventId)
        .map((e) => _eventToMatrixRoomEvent(e, myUserId: myUserId))
        .whereType<MatrixRoomEvent>();

    return events.take(limit).toList();
  }

  /// Returns the most recent event id in [roomId], or `null` if the room is
  /// not known to the client or has no events yet.
  ///
  /// Used to anchor [Channel.matrixSyncMarker] at join time so that
  /// subsequent [fetchRoomHistory] calls only return events posted after the
  /// joiner became a member.
  Future<String?> getLatestEventId(
    String roomId, {
    required DidManager didManager,
  }) async {
    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) return null;
    final timeline = await room.getTimeline(limit: 1);
    return timeline.events.isEmpty ? null : timeline.events.first.eventId;
  }

  /// Returns a stream of [MatrixRoomEvent]s received in [roomId].
  ///
  /// Yields both timeline events (message, reaction, etc.) and `m.receipt`
  /// ephemeral events so callers can track delivery with a single subscription.
  ///
  /// Parameters:
  /// - [roomId]: The ID of the Matrix room to subscribe to.
  /// - [didManager]: The DID manager used to ensure an authenticated session.
  /// - `excludeSelf`: When `true`, events sent by the local user are filtered
  ///   out before being yielded (default: `false`).
  Stream<MatrixRoomEvent> subscribeToRoom(
    String roomId, {
    required DidManager didManager,
    MatrixSubscriptionOptions options = const MatrixSubscriptionOptions(),
  }) async* {
    final client = await _ensureSession(didManager);
    final myUserId = _sessionManager.deriveUserId(
      (await didManager.getDidDocument()).id,
      serverName,
    );

    final controller = StreamController<MatrixRoomEvent>();

    final timelineSub = client.onTimelineEvent.stream
        .where((e) => e.room.id == roomId)
        .listen((event) {
          final msg = _eventToMatrixRoomEvent(event, myUserId: myUserId);
          if (msg == null) return;
          if (!options.excludeSelf || !msg.isFromMe) {
            controller.add(msg);
          }
        }, onError: controller.addError);

    final syncSub = client.onSync.stream.listen((syncUpdate) {
      final ephemeral = syncUpdate.rooms?.join?[roomId]?.ephemeral;
      if (ephemeral == null) return;

      for (final event in ephemeral) {
        if (event.type == 'm.typing') {
          final userIds =
              (event.content['user_ids'] as List?)?.cast<String>() ?? [];
          for (final userId in userIds) {
            if (options.excludeSelf && userId == myUserId) continue;
            controller.add(
              MatrixRoomEvent(
                id: '${roomId}_typing_$userId',
                type: 'm.typing',
                userId: userId,
                roomId: roomId,
                content: event.content,
                timestamp: DateTime.now().toUtc(),
              ),
            );
          }
          continue;
        }

        if (event.type != 'm.receipt') continue;

        final content = event.content;
        for (final entry in content.entries) {
          final eventId = entry.key;
          final mRead =
              (entry.value as Map<String, dynamic>?)
                      ?.cast<String, dynamic>()['m.read']
                  as Map<String, dynamic>?;
          if (mRead == null) continue;

          for (final userEntry in mRead.entries) {
            final userId = userEntry.key;
            if (options.excludeSelf && userId == myUserId) continue;
            final ts =
                (userEntry.value as Map<String, dynamic>?)?['ts'] as int?;
            controller.add(
              MatrixRoomEvent(
                id: eventId,
                type: 'm.receipt',
                userId: userId,
                roomId: roomId,
                content: {'event_id': eventId},
                timestamp: ts != null
                    ? DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true)
                    : DateTime.now().toUtc(),
              ),
            );
          }
        }
      }
    }, onError: controller.addError);

    try {
      yield* controller.stream;
    } finally {
      await timelineSub.cancel();
      await syncSub.cancel();
      await controller.close();
    }
  }

  /// Sends an `m.room.message` event whose content carries an attachment to
  /// [roomId]. Constructs the wire-format [matrix.MatrixFile] from [bytes],
  /// [contentType], and [filename] so callers stay transport-agnostic.
  /// Encryption is delegated to the matrix Dart SDK: in an encrypted room,
  /// [matrix.Room.sendFileEvent] uses the room's E2EE session to encrypt the
  /// bytes, uploads the ciphertext to the homeserver, and posts the event in
  /// one operation.
  ///
  /// Returns the server-assigned event id, or `null` if the matrix client
  /// does not produce one (for example when the event is queued offline).
  Future<String?> sendFileEvent(
    String roomId, {
    required Uint8List bytes,
    required String contentType,
    required DidManager didManager,
    String? filename,
    Map<String, dynamic>? extraContent,
  }) async {
    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) throw StateError('Matrix room $roomId not found');
    _assertRoomEncrypted(room, roomId);
    final file = matrix.MatrixFile.fromMimeType(
      bytes: bytes,
      name: filename ?? 'file',
      mimeType: contentType,
    );
    return room.sendFileEvent(file, extraContent: extraContent);
  }

  /// Downloads and decrypts the attachment carried by the message event
  /// [eventId] in [roomId]. Symmetric to [sendFileEvent]: the matrix Dart
  /// SDK retrieves the ciphertext from the homeserver and decrypts it using
  /// the room's E2EE session.
  Future<Uint8List> downloadFileForEvent(
    String roomId,
    String eventId, {
    required DidManager didManager,
  }) async {
    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) throw StateError('Matrix room $roomId not found');
    final event = await room.getEventById(eventId);
    if (event == null) {
      throw StateError('Matrix event $eventId not found in room $roomId');
    }
    final file = await event.downloadAndDecryptAttachment();
    return file.bytes;
  }

  /// Returns the maximum upload size allowed by the homeserver, in bytes.
  /// Returns null if the server does not report a limit.
  Future<int?> getMediaConfig({required DidManager didManager}) async {
    final client = await _ensureSession(didManager);
    final config = await client.getConfigAuthed();
    return config.mUploadSize;
  }

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
  /// Must be called once at app startup before [startCall], [leaveCall], or
  /// [watchCall]. The VoIP instance must be created in the Flutter layer using
  /// a concrete [matrix.WebRTCDelegate] implementation.
  void initializeVoIP(matrix.VoIP voip) {
    _voip = voip;
  }

  /// Creates a [matrix.VoIP] instance from [delegate] and an authenticated
  /// client for [didManager], then stores it for call operations.
  ///
  /// Preferred over [initializeVoIP] when the caller cannot hold a
  /// [matrix.Client] reference directly. Must be called before [startCall].
  Future<void> initializeVoIPWithDelegate({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
  }) async {
    final client = await _ensureSession(didManager);
    _voip = matrix.VoIP(client, delegate);
  }

  /// Lazily activates the single Matrix session for [didManager] and resolves
  /// the pending incoming MatrixRTC group call published in [roomId].
  ///
  /// This is the on-demand counterpart to [startCall]. Instead of holding a
  /// background sync at rest, the caller invokes this only after an
  /// out-of-band signal (a call push or mediator message) reports an incoming
  /// call for a specific channel. It logs in that one DID's Matrix session,
  /// initialises VoIP with [delegate] when needed, and returns the
  /// [matrix.GroupCallSession] the remote party created in [roomId].
  ///
  /// The membership is usually already present in room state, in which case
  /// this returns immediately. Otherwise it waits for the next sync to deliver
  /// it, up to [timeout].
  ///
  /// Throws [MatrixServiceException.incomingCallNotFound] if no group call
  /// surfaces within [timeout].
  Future<matrix.GroupCallSession> activateIncomingCall({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
    required String roomId,
    Duration timeout = MatrixRtcDefaults.incomingCallActivationTimeout,
  }) async {
    _logger.info('Activating incoming call for room $roomId', name: _logKey);

    final client = await _ensureSession(didManager);
    final voip = _voip ??= matrix.VoIP(client, delegate);

    final existing = _findGroupCallForRoom(voip, roomId);
    if (existing != null) {
      _logger.info(
        'Found existing group call ${existing.groupCallId} in room $roomId',
        name: _logKey,
      );
      return existing;
    }

    final completer = Completer<matrix.GroupCallSession>();
    final activation = (roomId: roomId, completer: completer);
    _pendingActivations.add(activation);

    // Subscribe once per VoIP instance to its single-subscription
    // onIncomingGroupCall stream so memberships that arrive in a later sync
    // resolve the activation.
    _ensureIncomingGroupCallListener(voip);

    // Drive VoIP discovery eagerly: a freshly authenticated session resolves
    // the room only via its alias directory and has not synced the room, so
    // the caller's m.call.member state event is not yet visible to the VoIP
    // constructor backfill. Loading the room and replaying its call
    // memberships covers that gap without depending on onRoomState firing for
    // state that predates the VoIP instance.
    unawaited(_discoverExistingGroupCall(voip, client, roomId));

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _logger.warning(
        'No incoming call surfaced in room $roomId within '
        '${timeout.inSeconds}s',
        name: _logKey,
      );
      throw MatrixServiceException.incomingCallNotFound(roomId);
    } finally {
      _pendingActivations.remove(activation);
    }
  }

  /// Listens to [voip]'s single-subscription [matrix.VoIP.onIncomingGroupCall]
  /// stream exactly once, cancelling any subscription to a previous instance.
  ///
  /// onIncomingGroupCall fires synchronously inside
  /// `createGroupCallFromRoomStateEvent` right after `setGroupCallById`,
  /// covering both the VoIP constructor backfill and the onRoomState-from-sync
  /// path. Listening here once per instance avoids the "Stream has already
  /// been listened to" error that re-listening per call would cause on the
  /// cached VoIP instance.
  void _ensureIncomingGroupCallListener(matrix.VoIP voip) {
    if (identical(_incomingCallListenerVoip, voip)) return;
    _incomingGroupCallSubscription?.cancel();
    _incomingCallListenerVoip = voip;
    _incomingGroupCallSubscription = voip.onIncomingGroupCall.stream.listen(
      (_) => _resolvePendingActivations(voip),
    );
  }

  void _resolvePendingActivations(matrix.VoIP voip) {
    for (final activation in List.of(_pendingActivations)) {
      if (activation.completer.isCompleted) continue;
      final session = _findGroupCallForRoom(voip, activation.roomId);
      if (session != null) activation.completer.complete(session);
    }
  }

  /// Loads [roomId] when the session has not synced it yet, then replays every
  /// call membership already present in its state through
  /// [matrix.VoIP.createGroupCallFromRoomStateEvent], which is idempotent.
  ///
  /// This is the deterministic counterpart to the onIncomingGroupCall listener:
  /// the listener only covers memberships that arrive in a future sync, whereas
  /// the caller's m.call.member event is typically already in the room state by
  /// the time the callee activates. Best-effort by design; any failure leaves
  /// the activation to resolve via the listener or time out.
  Future<void> _discoverExistingGroupCall(
    matrix.VoIP voip,
    matrix.Client client,
    String roomId,
  ) async {
    try {
      if (client.getRoomById(roomId) == null) {
        await client.waitForRoomInSync(roomId, join: true);
      }
      final room = client.getRoomById(roomId);
      if (room == null) {
        _logger.warning(
          'Room $roomId did not load after sync; relying on '
          'onIncomingGroupCall for incoming call discovery',
          name: _logKey,
        );
        return;
      }
      for (final memberships in room.getCallMembershipsFromRoom(voip).values) {
        for (final membership in memberships) {
          await voip.createGroupCallFromRoomStateEvent(membership);
        }
      }
      _resolvePendingActivations(voip);
    } catch (e, stackTrace) {
      _logger.error(
        'Eager incoming call discovery failed for room $roomId',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
  }

  matrix.GroupCallSession? _findGroupCallForRoom(
    matrix.VoIP voip,
    String roomId,
  ) {
    for (final entry in voip.groupCalls.entries) {
      if (entry.key.roomId == roomId) return entry.value;
    }
    return null;
  }

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
  /// SFU backend.
  ///
  /// Publishes an `m.call.member` state event so the remote party can
  /// discover the LiveKit room. Call [initializeVoIP] before invoking this.
  ///
  /// Parameters:
  /// - [didManager]: The DID manager for the local participant.
  /// - [roomId]: Matrix room ID for the call.
  /// - [livekitServiceUrl]: WebSocket URL of the LiveKit server.
  /// - [livekitAlias]: Unique call identifier within the LiveKit server.
  /// - [callId]: Stable MatrixRTC call ID; defaults to [roomId].
  Future<matrix.GroupCallSession> startCall({
    required DidManager didManager,
    required String roomId,
    required String livekitServiceUrl,
    required String livekitAlias,
    String? callId,
  }) async {
    final voip = _voip;
    if (voip == null) throw MatrixServiceException.voipNotInitialized();

    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) throw MatrixServiceException.roomNotFound(roomId);

    final backend = matrix.LiveKitBackend(
      livekitServiceUrl: livekitServiceUrl,
      livekitAlias: livekitAlias,
      e2eeEnabled: MatrixRtcDefaults.e2eeEnabled,
    );

    final session = await voip.fetchOrCreateGroupCall(
      callId ?? roomId,
      room,
      backend,
      MatrixRtcCallType.call.value,
      MatrixRtcCallScope.room.value,
      preShareKey: MatrixRtcDefaults.preShareKey,
    );

    if (session.state != matrix.GroupCallState.entered) {
      await session.enter();
    }

    return session;
  }

  /// Leaves the active MatrixRTC group call in [roomId] with [callId].
  Future<void> leaveCall({
    required String roomId,
    required String callId,
  }) async {
    final session = _voip?.getGroupCallById(roomId, callId);
    if (session == null) return;
    await session.leave();
  }

  /// Returns a stream of [matrix.MatrixRTCCallEvent]s for the given call.
  ///
  /// Returns `null` if VoIP is not initialized or no session exists for the
  /// given IDs.
  Stream<matrix.MatrixRTCCallEvent>? watchCall({
    required String roomId,
    required String callId,
  }) {
    return _voip?.getGroupCallById(roomId, callId)?.matrixRTCEventStream.stream;
  }

  MatrixRoomEvent? _eventToMatrixRoomEvent(
    matrix.Event event, {
    String? myUserId,
  }) {
    final typeStr = event.type;

    return MatrixRoomEvent(
      id: event.eventId,
      type: typeStr,
      userId: event.senderId,
      roomId: event.room.id,
      content: Map<String, dynamic>.from(event.content),
      timestamp: event.originServerTs,
      isFromMe: myUserId != null && event.senderId == myUserId,
      stateKey: event.stateKey,
    );
  }

  static void _assertRoomEncrypted(matrix.Room room, String roomId) {
    if (!room.encrypted) {
      throw StateError(
        'Matrix room $roomId does not have end-to-end encryption enabled. '
        'Refusing to operate on an unencrypted room.',
      );
    }
  }

  /// Returns an authenticated client, transparently re-authenticating via
  /// [loginWithDid] when the session has expired or the refresh token is
  /// exhausted.
  Future<matrix.Client> _ensureSession(DidManager didManager) async {
    final did = (await didManager.getDidDocument()).id;

    await loginWithDid(didManager);
    final client = await _sessionManager.getAuthenticatedClient(did);
    if (client == null) {
      throw const MatrixAuthException();
    }
    return client;
  }

  /// Disposes the underlying session manager, aborting all matrix sync
  /// loops and closing each cached client's database. Safe to call
  /// multiple times.
  Future<void> dispose() => _sessionManager.dispose();

  /// Waits until the matrix client owned by [didManager] has converged on
  /// the membership and device-key state needed to encrypt a message that
  /// every DID in [expectedDids] can decrypt.
  ///
  /// Matrix creates the outbound megolm session lazily on the first send,
  /// pulling participants and their device keys from the local cache. If
  /// sync hasn't yet reflected a recent join (or the joiner's `/keys/query`
  /// hasn't completed), the session is shared only with stale recipients
  /// and later messages are unreadable for everyone added since.
  ///
  /// In production the natural latency between accept-offer and first
  /// send hides this race. Tests fire both within milliseconds, so this
  /// helper drains a sync cycle and forces the device-key fetch up front.
  /// It is intended for test fixtures only — production code should not
  /// need to call it.
  Future<void> waitForRoomEncryptionReady({
    required String roomId,
    required DidManager didManager,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final client = await _ensureSession(didManager);
    final expectedUserIds = expectedDids
        .map((did) => _sessionManager.deriveUserId(did, homeserver.host))
        .toSet();

    final deadline = DateTime.now().add(timeout);
    while (true) {
      await client.oneShotSync();
      await client.updateUserDeviceKeys(additionalUsers: expectedUserIds);
      final inFlight = client.userDeviceKeysLoading;
      if (inFlight != null) await inFlight;

      final room = client.getRoomById(roomId);
      if (room != null) {
        final participants = await room.requestParticipants([
          matrix.Membership.join,
        ], true);
        final joinedIds = participants.map((p) => p.id).toSet();
        final missingMembership = expectedUserIds.difference(joinedIds);
        final missingKeys = expectedUserIds.where((uid) {
          final keys = client.userDeviceKeys[uid];
          return keys == null || keys.outdated || keys.deviceKeys.isEmpty;
        }).toSet();
        if (missingMembership.isEmpty && missingKeys.isEmpty) return;
      }

      if (!DateTime.now().isBefore(deadline)) {
        throw StateError(
          'Timed out waiting for matrix room $roomId to converge on '
          'membership/device-key state for $expectedUserIds',
        );
      }
      await Future<void>.delayed(pollInterval);
    }
  }
}
