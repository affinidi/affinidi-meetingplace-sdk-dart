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

  final ControlPlaneSDK _controlPlaneSDK;
  final MatrixSessionManager _sessionManager;

  Uri get homeserver => _sessionManager.homeserver;

  /// Obtains a Matrix JWT from the control plane for [didManager], logs in,
  /// and returns the Matrix user ID.
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

  Future<void> joinRoom(String roomId, {required DidManager didManager}) async {
    final client = await _ensureSession(didManager);
    await client.joinRoom(roomId);
  }

  void dispose() {
    _sessionManager.dispose();
  }

  /// Returns an authenticated client, transparently re-authenticating via
  /// [loginWithDid] when the session has expired or the refresh token is
  /// exhausted.
  Future<dynamic> _ensureSession(DidManager didManager) async {
    final did = (await didManager.getDidDocument()).id;

    try {
      return await _sessionManager.getAuthenticatedClient(did);
    } on MatrixAuthException {
      await loginWithDid(didManager);
      return _sessionManager.getAuthenticatedClient(did);
    }
  }
}
