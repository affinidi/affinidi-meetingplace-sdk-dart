import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import 'matrix_auth_exception.dart';
import 'matrix_config.dart';
import 'matrix_session_manager.dart';

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

  /// Creates a new Matrix room, optionally inviting specified users.
  /// The method ensures an authenticated session, transparently
  /// re-authenticating if necessary, before performing the room creation
  /// operation.
  ///
  /// Note: The invited users should be specified as DIDs, which will be
  /// internally converted to Matrix user IDs using the session manager's
  /// derivation logic.
  ///
  /// Parameters:
  /// - [didManager]: The DID manager used to ensure an authenticated session
  ///   for the room creation operation.
  /// - [inviteUsers]: Optional list of DIDs to invite to the newly created
  ///   room.
  ///
  /// Returns: The ID of the newly created Matrix room.
  Future<String> createRoom({
    required DidManager didManager,
    List<String>? inviteUsers,
  }) async {
    final client = await _ensureSession(didManager);
    return client.createRoom(
      invite: inviteUsers
          ?.map((did) => _sessionManager.deriveUserId(did, homeserver.host))
          .toList(),
    );
  }

  /// Joins an existing Matrix room by its ID.
  /// The method ensures an authenticated session, transparently
  /// re-authenticating if necessary, before performing the room join operation.
  ///
  /// Parameters:
  /// - [roomId]: The ID of the Matrix room to join.
  /// - [didManager]: The DID manager used to ensure an authenticated session
  ///   for the room join operation.
  ///
  /// Returns: A Future that completes when the room join operation is
  /// successful.
  Future<void> joinRoom(String roomId, {required DidManager didManager}) async {
    final client = await _ensureSession(didManager);
    await client.joinRoom(roomId);
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
