import '../../../meeting_place_core.dart' show MatrixService;
import 'matrix_service.dart' show MatrixService;
import 'matrix_session_manager.dart' show MatrixSessionManager;

/// Thrown by [MatrixSessionManager] when a session does not exist, the access
/// token is missing, or both access and refresh tokens have expired.
///
/// The receiver should obtain a fresh JWT and call [MatrixSessionManager.loginWithJwt]
/// (or [MatrixService.loginWithDid]) before retrying the operation.
class MatrixAuthException implements Exception {
  const MatrixAuthException([
    this.message = 'Matrix session expired or not authenticated',
  ]);

  /// A descriptive message providing details about the authentication error.
  final String message;

  @override
  String toString() => 'MatrixAuthException: $message';
}
