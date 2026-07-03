import 'dart:async';
import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';
import '../matrix_session_manager.dart';
import 'matrix_session_accessor.dart';

/// Room-domain operations for Matrix: room lifecycle (create/join/leave),
/// membership (invite/kick), event send/receive, history, and media transfer.
///
/// Holds no authentication state of its own — it obtains authenticated clients
/// through [EnsureMatrixSession] and derives user IDs and sync control via
/// [MatrixSessionManager]. Constructed and owned by `MatrixService`, which
/// exposes these operations through its public facade.
class MatrixRoomService {
  MatrixRoomService({
    required EnsureMatrixSession ensureSession,
    required MatrixSessionManager sessionManager,
  }) : _ensureSession = ensureSession,
       _sessionManager = sessionManager;

  final EnsureMatrixSession _ensureSession;
  final MatrixSessionManager _sessionManager;

  /// Power level required to enable MatrixRTC group calls via
  /// [matrix.Room.enableGroupCalls]. Both the room creator and every invited
  /// participant must hold this level so either party can start a call.
  static const _groupCallPowerLevel = 100;

  /// Key for the per-user power level map in the Matrix `m.room.power_levels`
  /// content. Defined by the Matrix spec; extracted here to avoid a bare
  /// string literal next to the numeric power level.
  static const _powerLevelUsersKey = 'users';

  // Matrix event type strings not covered by matrix.EventTypes.
  static const _eventTypeRead = 'm.read';
  static const _eventTypeTyping = 'm.typing';
  static const _eventTypeReceipt = 'm.receipt';

  // Content key strings for Matrix event payloads.
  static const _keyEventId = 'event_id';
  static const _keyRedacts = 'redacts';
  static const _keyActive = 'active';
  static const _keyTimeoutMs = 'timeoutMs';
  static const _keyUserIds = 'user_ids';
  static const _keyMRead = 'm.read';
  static const _keyTs = 'ts';

  String get _serverName => _sessionManager.serverName;

  Uri get _homeserver => _sessionManager.homeserver;

  /// Creates a new Matrix room with a deterministic alias derived from the
  /// channel DIDs, optionally inviting specified users.
  ///
  /// For two-party channels (individual, OOB) pass both [channelDid] and
  /// [otherPartyChannelDid]; for group channels pass only [channelDid].
  /// See [deriveRoomAliasLocalpart] for the localpart semantics.
  ///
  /// Both the creator and every invited user are granted power level 100 so
  /// either party can start or join a MatrixRTC group call regardless of who
  /// created the room. The group-call member state event requires power 50 by
  /// default, but only a power-100 user can enable group calls for the room
  /// (`Room.enableGroupCalls`), so a non-creator party would otherwise be
  /// unable to join. Co-owning the room is the expected model for a
  /// peer-to-peer channel and keeps the default per-event protections intact.
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
    final creatorUserId = client.userID;
    if (creatorUserId == null) {
      throw MatrixServiceException.missingUserId();
    }
    final invitedUserIds = inviteUsers
        ?.map((did) => _sessionManager.deriveUserId(did, _serverName))
        .toList();
    return client.createRoom(
      roomAliasName: deriveRoomAliasLocalpart(
        channelDid: channelDid,
        otherPartyChannelDid: otherPartyChannelDid,
      ),
      invite: invitedUserIds,
      powerLevelContentOverride: {
        _powerLevelUsersKey: {
          creatorUserId: _groupCallPowerLevel,
          for (final userId in invitedUserIds ?? const <String>[])
            userId: _groupCallPowerLevel,
        },
      },
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
      homeserverHost: _serverName,
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
  /// Attempts to use the stored room ID when available (set at inauguration
  /// time) so that the lookup works without alias registration. Falls back to
  /// alias derivation for channels that predate this field.
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
        homeserverHost: _serverName,
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
    final userId = _sessionManager.deriveUserId(did, _serverName);
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
    final userId = _sessionManager.deriveUserId(did, _serverName);
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

    if (eventType == _eventTypeRead) {
      final eventId = content[_keyEventId] as String;
      await room.setReadMarker(eventId, mRead: eventId);
      return null;
    }

    if (eventType == matrix.EventTypes.Redaction) {
      final targetEventId = content[_keyRedacts] as String;
      await room.redactEvent(targetEventId);
      return null;
    }

    if (eventType == _eventTypeTyping) {
      final active = content[_keyActive] as bool;
      final timeoutMs = content[_keyTimeoutMs] as int?;
      await room.setTyping(active, timeout: active ? timeoutMs : null);
      return null;
    }

    return room.sendEvent(content, type: eventType);
  }

  /// Returns recent events from [roomId] as [MatrixRoomEvent]s.
  ///
  /// When [sinceEventId] is provided, uses `/context/{sinceEventId}` to obtain
  /// a precise pagination token at that position and sets it as `prev_batch`
  /// before calling `requestHistory(direction: f)`. This ensures only events
  /// strictly newer than [sinceEventId] are fetched from the homeserver.
  ///
  /// When [sinceEventId] is null, calls `requestHistory(direction: f)` from
  /// the room's existing `prev_batch`, pulling any events newer than the local
  /// database into the local database before reading the timeline.
  ///
  /// Using `getTimeline` (rather than the raw HTTP API) means the Matrix SDK
  /// handles decryption — including automatically retrying when a missing
  /// session key arrives later via background sync.
  Future<List<MatrixRoomEvent>> fetchRoomHistory(
    String roomId, {
    required DidManager didManager,
    int limit = 50,
    String? sinceEventId,
    bool forceSync = false,
  }) async {
    final client = await _ensureSession(
      didManager,
      keepSyncActiveAfterLogin: false,
    );

    if (forceSync) {
      await client.oneShotSync();
    }

    final myUserId =
        client.userID ??
        _sessionManager.deriveUserId(
          (await didManager.getDidDocument()).id,
          _serverName,
        );
    final room = client.getRoomById(roomId);
    if (room == null) return [];

    if (sinceEventId != null) {
      final context = await client.getEventContext(
        roomId,
        sinceEventId,
        limit: 0,
      );
      final token = context.end;
      if (token != null) {
        room.prev_batch = token;
      }
    }

    await room.requestHistory(
      historyCount: limit,
      direction: matrix.Direction.f,
    );

    final timeline = await room.getTimeline(limit: limit);

    final events = timeline.events
        .takeWhile((e) => sinceEventId == null || e.eventId != sinceEventId)
        .map((e) => _eventToMatrixRoomEvent(e, myUserId: myUserId))
        .whereType<MatrixRoomEvent>();

    return events.take(limit).toList();
  }

  /// Performs a single Matrix sync round-trip for the session associated with
  /// [didManager], updating the local event database with any events that
  /// arrived since the last sync.
  ///
  /// Call this before [fetchRoomHistory] in contexts where a push notification
  /// may have arrived before the background sync loop had a chance to deliver
  /// the triggering event to the local database.
  Future<void> oneShotSync({required DidManager didManager}) async {
    final client = await _ensureSession(didManager);
    await client.oneShotSync();
  }

  /// Returns the most recent event id in [roomId], or `null` if the room is
  /// not known to the client or has no events yet.
  ///
  /// Used to anchor [Channel.messageSyncMarker] at join time so that
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

    final myUserId =
        client.userID ?? _sessionManager.deriveUserId(did, _homeserver.host);

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
        if (event.type == _eventTypeTyping) {
          final userIds =
              (event.content[_keyUserIds] as List?)?.cast<String>() ?? [];
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

        if (event.type != _eventTypeReceipt) continue;

        final content = event.content;
        for (final entry in content.entries) {
          final eventId = entry.key;
          final mRead =
              (entry.value as Map<String, dynamic>?)
                      ?.cast<String, dynamic>()[_keyMRead]
                  as Map<String, dynamic>?;
          if (mRead == null) continue;

          for (final userEntry in mRead.entries) {
            final userId = userEntry.key;
            if (options.excludeSelf && userId == myUserId) continue;
            final ts =
                (userEntry.value as Map<String, dynamic>?)?[_keyTs] as int?;
            controller.add(
              MatrixRoomEvent(
                id: eventId,
                type: _eventTypeReceipt,
                userId: userId,
                roomId: roomId,
                content: {_keyEventId: eventId},
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
        .map((did) => _sessionManager.deriveUserId(did, _homeserver.host))
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
