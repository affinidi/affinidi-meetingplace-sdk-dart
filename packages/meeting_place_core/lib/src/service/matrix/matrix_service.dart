import 'dart:async';
import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../entity/channel.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import 'matrix_auth_exception.dart';
import 'matrix_config.dart';
import 'matrix_room_alias.dart';
import 'matrix_room_event.dart';
import 'matrix_service_exception.dart';
import 'matrix_session_manager.dart';
import 'matrix_subscription_options.dart';

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

  /// Exposes the homeserver URI from the session manager.
  Uri get homeserver => _sessionManager.homeserver;

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
      return cachedClient.userID!;
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
          ?.map((did) => _sessionManager.deriveUserId(did, homeserver.host))
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
      homeserverHost: homeserver.host,
    );
    final response = await client.getRoomIdByAlias(alias);
    final roomId = response.roomId;
    if (roomId == null) {
      throw StateError('Matrix alias $alias did not resolve to a room id');
    }
    return roomId;
  }

  /// Resolves the Matrix room ID for [channel] by deriving the appropriate
  /// alias. Group channels hash only the group DID (carried in
  /// `otherPartyPermanentChannelDid`); individual channels hash both party
  /// DIDs commutatively.
  Future<String> resolveRoomIdForChannel({
    required DidManager didManager,
    required Channel channel,
  }) {
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
        homeserverHost: homeserver.host,
      ),
    );
    var room = client.getRoomById(roomId);
    if (room == null) {
      await client.oneShotSync();
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
    final userId = _sessionManager.deriveUserId(did, homeserver.host);
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
    final userId = _sessionManager.deriveUserId(did, homeserver.host);
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
    final room = await _resolveEncryptedRoom(client, roomId);

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
    final client = await _ensureSession(
      didManager,
      keepSyncActiveAfterLogin: false,
    );

    final myUserId = _sessionManager.deriveUserId(
      (await didManager.getDidDocument()).id,
      homeserver.host,
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
    final client = await _ensureSession(
      didManager,
      keepSyncActiveAfterLogin: true,
    );
    final did = (await didManager.getDidDocument()).id;
    final myUserId = _sessionManager.deriveUserId(did, homeserver.host);

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

    _sessionManager.activateSync(did, client);
    try {
      yield* controller.stream;
    } finally {
      await timelineSub.cancel();
      await syncSub.cancel();
      await controller.close();
      _sessionManager.deactivateSync(
        did,
        client,
        lingerDuration: options.syncGracePeriodDuration,
        keepSyncActive: options.keepSyncActiveOnEnd,
      );
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
    final room = await _resolveEncryptedRoom(client, roomId);
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

    // getEventById returns DB-cached events without decrypting them; only its
    // network path decrypts. Decrypt here so attachments on historical
    // encrypted events can be downloaded (store:true also repairs the cache).
    var decryptedEvent = event;
    if (event.type == matrix.EventTypes.Encrypted && client.encryptionEnabled) {
      decryptedEvent = await client.encryption!.decryptRoomEvent(
        event,
        store: true,
      );
    }
    if (decryptedEvent.type == matrix.EventTypes.Encrypted) {
      throw MatrixServiceException.mediaDecryptionFailed(
        roomId: roomId,
        eventId: eventId,
      );
    }

    final file = await decryptedEvent.downloadAndDecryptAttachment();
    return file.bytes;
  }

  /// Returns the maximum upload size allowed by the homeserver, in bytes.
  /// Returns null if the server does not report a limit.
  Future<int?> getMediaConfig({required DidManager didManager}) async {
    final client = await _ensureSession(didManager);
    final config = await client.getConfigAuthed();
    return config.mUploadSize;
  }

  MatrixRoomEvent? _eventToMatrixRoomEvent(
    matrix.Event event, {
    String? myUserId,
  }) {
    final typeStr = event.type;

    final content = Map<String, dynamic>.from(event.content);
    // Matrix room version 11+ delivers the redaction target in a top-level
    // `redacts` field instead of inside `content`. Surface it in `content`
    // so downstream handlers (reaction undo, delete-for-everyone) resolve the
    // target the same way regardless of room version.
    final redacts = event.redacts;
    if (redacts != null && content['redacts'] == null) {
      content['redacts'] = redacts;
    }

    return MatrixRoomEvent(
      id: event.eventId,
      type: typeStr,
      userId: event.senderId,
      roomId: event.room.id,
      content: content,
      timestamp: event.originServerTs,
      isFromMe: myUserId != null && event.senderId == myUserId,
      stateKey: event.stateKey,
    );
  }

  /// Returns the [matrix.Room] for [roomId], ensuring it is encrypted.
  /// If the room is missing or not yet marked as encrypted (e.g. because
  /// background sync is disabled), performs a one-shot sync to load the
  /// latest room state before checking again.
  Future<matrix.Room> _resolveEncryptedRoom(
    matrix.Client client,
    String roomId,
  ) async {
    var room = client.getRoomById(roomId);
    if (room == null || !room.encrypted) {
      await client.oneShotSync();
      room = client.getRoomById(roomId);
    }
    if (room == null) throw StateError('Matrix room $roomId not found');
    _assertRoomEncrypted(room, roomId);
    return room;
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
