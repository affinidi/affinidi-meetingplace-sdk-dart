import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import '../errors/vta_client_exception.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'auth_protocol.dart';
import 'session_manager.dart';

class VtaAuthService {
  VtaAuthService({
    required this.api,
    required this.sessionManager,
    required this.holderDid,
    required this.vtaDid,
    required this.protocol,
    DateTime Function()? clock,
  }) : _clock = clock ?? _defaultClock;

  final VtaAuthApi api;
  final VtaSessionManager sessionManager;
  final String holderDid;
  final String vtaDid;
  final VtaAuthProtocol protocol;
  final DateTime Function() _clock;

  Future<VtaAuthenticateResult> connect({
    String? purpose,
    List<String> scopes = const <String>[],
    bool syncWhoAmIAfterConnect = false,
  }) async {
    final challengeRequest = VtaChallengeRequest(
      subject: holderDid,
      purpose: purpose,
    )..validate();

    final challenge = await api.challenge(challengeRequest);

    final authenticateRequest = VtaAuthenticateRequest.create(
      holderDid: holderDid,
      vtaDid: vtaDid,
      challenge: challenge.challenge,
      sessionId: challenge.sessionId,
      scopes: scopes,
      issuedAt: _clock().toUtc(),
    )..validate();

    final result = await api.authenticate(
      request: authenticateRequest,
      protocol: protocol,
    );

    sessionManager.applyAuthenticateResult(result);
    if (syncWhoAmIAfterConnect) {
      await sessionManager.syncWhoAmIAfterReconnectIfEnabled();
    }
    return result;
  }

  Future<VtaAuthenticateResult> refresh({
    List<String> scopes = const <String>[],
  }) async {
    final refreshToken = sessionManager.tokens?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const VtaAuthException(
        'Refresh token is unavailable; connect first.',
        code: 'e.vta.auth.refresh_missing',
      );
    }
    final request = VtaRefreshRequest.create(
      holderDid: holderDid,
      vtaDid: vtaDid,
      refreshToken: refreshToken,
      scopes: scopes,
      issuedAt: _clock().toUtc(),
    )..validate();

    final result = await api.refresh(request: request, protocol: protocol);
    sessionManager.applyAuthenticateResult(result);
    if (sessionManager.shouldSyncAfterRefresh) {
      await sessionManager.refreshWhoAmI();
    }
    return result;
  }

  Future<String> getValidAccessToken({List<String> scopes = const <String>[]}) {
    return sessionManager.getValidAccessToken(scopes: scopes);
  }

  Future<SessionInfo> whoAmI({
    bool ensureValidAccessToken = true,
    List<String> scopes = const <String>[],
  }) async {
    if (ensureValidAccessToken) {
      await getValidAccessToken(scopes: scopes);
    }
    return sessionManager.refreshWhoAmI();
  }

  Future<VtaAuthenticateResult> reconnect({
    String? purpose,
    List<String> scopes = const <String>[],
  }) {
    return connect(
      purpose: purpose,
      scopes: scopes,
      syncWhoAmIAfterConnect: true,
    );
  }

  void disconnect() {
    sessionManager.clear();
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
}
