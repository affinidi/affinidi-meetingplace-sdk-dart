import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import 'matrix_auth_exception.dart';
import 'matrix_config.dart';
import 'matrix_room_alias.dart';
import 'matrix_session_manager.dart';
import 'matrix_room_event.dart';

/// High-level Matrix service that orchestrates JWT acquisition and room
/// operations.
///
/// Responsibilities:
/// - Obtaining Matrix JWTs from the control plane via [loginWithDid].
/// - Delegating session lifecycle (client creation, token refresh) to
///   [MatrixSessionManager].
/// - Exposing room operations ([createRoom], [joinRoom]) that transparently
///   re-authenticate when a session has expired.
class MatrixService {
  MatrixService({
    required MatrixConfig config,
    required ControlPlaneSDK controlPlaneSDK,
    MatrixSessionManager? sessionManager,
  }) : _controlPlaneSDK = controlPlaneSDK,
       _sessionManager = sessionManager ?? MatrixSessionManager(config: config);

  /// Control plane SDK for executing commands to obtain Matrix JWTs.
  final ControlPlaneSDK _controlPlaneSDK;

  /// Manages Matrix sessions, including client instances and token refresh.
  final MatrixSessionManager _sessionManager;

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

    final matrixTokenOutput = await _controlPlaneSDK.execute(
      MatrixTokenCommand(didManager: didManager, homeserver: homeserver),
    );

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
    return client.createRoom(
      roomAliasName: deriveRoomAliasLocalpart(
        channelDid: channelDid,
        otherPartyChannelDid: otherPartyChannelDid,
      ),
      invite: inviteUsers
          ?.map((did) => _sessionManager.deriveUserId(did, homeserver.host))
          .toList(),
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

  /// Joins the Matrix room for a channel via its deterministic alias.
  Future<void> joinChannelRoom({
    required DidManager didManager,
    required String channelDid,
    String? otherPartyChannelDid,
  }) async {
    final client = await _ensureSession(didManager);
    await client.joinRoom(
      deriveRoomAlias(
        channelDid: channelDid,
        otherPartyChannelDid: otherPartyChannelDid,
        homeserverHost: homeserver.host,
      ),
    );
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

  /// Disposes of the session manager, cleaning up resources.
  void dispose() {
    _sessionManager.dispose();
  }

  MatrixRoomEvent? _eventToMatrixRoomEvent(
    matrix.Event event, {
    String? myUserId,
  }) {
    final typeStr = event.type;

    return MatrixRoomEvent(
      id: event.eventId,
      type: typeStr,
      sender: event.senderId,
      roomId: event.room.id,
      content: Map<String, dynamic>.from(event.content),
      timestamp: event.originServerTs,
      isFromMe: myUserId != null && event.senderId == myUserId,
    );
  }

  /// Returns an authenticated client, transparently re-authenticating via
  /// [loginWithDid] when the session has expired or the refresh token is
  /// exhausted.
  Future<matrix.Client> _ensureSession(DidManager didManager) async {
    final did = (await didManager.getDidDocument()).id;

    try {
      return await _sessionManager.getAuthenticatedClient(did);
    } on MatrixAuthException {
      await loginWithDid(didManager);
      return _sessionManager.getAuthenticatedClient(did);
    }
  }
}
