// ignore_for_file: avoid_print

import 'dart:async';

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
  ///
  /// Returns: The Matrix user ID associated with the logged-in session.
  Future<String> loginWithDid(DidManager didManager) async {
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
    print(
      'demo: createRoom user=${await _userIdOf(didManager)} '
      'invite=${inviteUsers?.length ?? 0}',
    );
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

  Future<void> leaveRoom(
    String roomId, {
    required DidManager didManager,
  }) async {
    print('demo: leaveRoom user=${await _userIdOf(didManager)} room=$roomId');
    final client = await _ensureSession(didManager);
    await client.leaveRoom(roomId);
  }

  Future<void> inviteUser(
    String roomId, {
    required String did,
    required DidManager didManager,
  }) async {
    print(
      'demo: inviteUser user=${await _userIdOf(didManager)} '
      'room=$roomId invitedDid=$did',
    );
    final client = await _ensureSession(didManager);
    final userId = _sessionManager.deriveUserId(did, homeserver.host);
    await client.inviteUser(roomId, userId);
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
    print(
      'demo: sendRoomEvent user=${await _userIdOf(didManager)} '
      'room=$roomId type=$eventType',
    );
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
    print(
      'demo: fetchRoomHistory user=${await _userIdOf(didManager)} '
      'room=$roomId limit=$limit since=$sinceEventId',
    );
    final client = await _ensureSession(didManager);
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
        .map((e) {
          print(
            'demo: fetched timeline event room=$roomId '
            'type=${e.type} '
            'id=${e.eventId} from=${e.senderId}',
          );
          return _eventToMatrixRoomEvent(e, myUserId: myUserId);
        })
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
    print(
      'demo: getLatestEventId user=${await _userIdOf(didManager)} '
      'room=$roomId',
    );
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
      homeserver.host,
    );
    print('demo: subscribeToRoom room=$roomId user=$myUserId');

    final controller = StreamController<MatrixRoomEvent>();

    final timelineSub = client.onTimelineEvent.stream
        .where((e) => e.room.id == roomId)
        .listen((event) {
          final msg = _eventToMatrixRoomEvent(event, myUserId: myUserId);
          if (msg != null && (!options.excludeSelf || !msg.isFromMe)) {
            print(
              'demo: received timeline event room=$roomId '
              'type=${event.type} '
              'id=${event.eventId} from=${event.senderId}',
            );
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
            print('demo: received typing event room=$roomId from=$userId');
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
            print(
              'demo: received receipt event room=$roomId '
              'eventId=$eventId from=$userId',
            );
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

  Future<String> _userIdOf(DidManager didManager) async {
    final did = (await didManager.getDidDocument()).id;
    return _sessionManager.deriveUserId(did, homeserver.host);
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
}
