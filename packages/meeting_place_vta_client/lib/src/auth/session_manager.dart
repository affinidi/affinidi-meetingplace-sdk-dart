import '../client/vta_client.dart';
import '../errors/vta_client_exception.dart';
import '../models/auth_tokens.dart';
import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import 'auth_models.dart';
import 'auth_protocol.dart';

enum VtaWhoAmISyncPolicy { never, onRefresh, onReconnect, onRefreshOrReconnect }

class VtaSessionManager {
  VtaSessionManager({
    required this.client,
    required this.holderDid,
    required this.vtaDid,
    required this.protocol,
    DateTime Function()? clock,
    this.refreshSkew = const Duration(seconds: 45),
    this.whoAmISyncPolicy = VtaWhoAmISyncPolicy.onRefreshOrReconnect,
  }) : _clock = clock ?? _defaultClock;

  final VtaClient client;
  final String holderDid;
  final String vtaDid;
  final VtaAuthProtocol protocol;
  final Duration refreshSkew;
  final VtaWhoAmISyncPolicy whoAmISyncPolicy;
  final DateTime Function() _clock;

  _SessionState? _state;
  Future<String>? _refreshInFlight;

  AuthTokens? get tokens => _state?.tokens;
  SessionInfo? get session => _state?.session;
  SessionInfo? get sessionInfo => _state?.session;
  DateTime? get accessExpiresAt => _state?.accessExpiresAt;
  DateTime? get refreshExpiresAt => _state?.refreshExpiresAt;

  bool get hasSession => _state != null;
  bool get isRefreshInFlight => _refreshInFlight != null;

  bool get shouldSyncAfterRefresh =>
      whoAmISyncPolicy == VtaWhoAmISyncPolicy.onRefresh ||
      whoAmISyncPolicy == VtaWhoAmISyncPolicy.onRefreshOrReconnect;

  bool get shouldSyncAfterReconnect =>
      whoAmISyncPolicy == VtaWhoAmISyncPolicy.onReconnect ||
      whoAmISyncPolicy == VtaWhoAmISyncPolicy.onRefreshOrReconnect;

  void applyAuthenticateResult(VtaAuthenticateResult result) {
    _state = _SessionState.fromAuthenticateResult(result);
    client.setAuthToken(result.tokens.accessToken);
  }

  void applySessionInfo(SessionInfo info) {
    final state = _state;
    if (state == null) {
      throw const VtaAuthException(
        'No authenticated session is available.',
        code: 'e.vta.auth.session_missing',
      );
    }
    _state = state.copyWith(session: info);
  }

  Future<String> getValidAccessToken({
    List<String> scopes = const <String>[],
  }) async {
    final state = _state;
    if (state == null) {
      throw const VtaAuthException(
        'No authenticated session is available.',
        code: 'e.vta.auth.session_missing',
      );
    }

    final now = _clock().toUtc();
    if (state.accessExpiresAt.isAfter(now.add(refreshSkew))) {
      return state.tokens.accessToken;
    }

    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final refreshTask = _refreshAccessToken(scopes: scopes, now: now);
    _refreshInFlight = refreshTask;
    try {
      return await refreshTask;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<SessionInfo> refreshWhoAmI() async {
    final sessionInfo = await client.auth.whoAmI(
      request: VtaWhoAmIRequest.create(
        holderDid: holderDid,
        vtaDid: vtaDid,
        issuedAt: _clock().toUtc(),
      ),
      protocol: protocol,
    );
    applySessionInfo(sessionInfo);
    return sessionInfo;
  }

  Future<SessionInfo?> syncWhoAmIAfterReconnectIfEnabled() async {
    if (!shouldSyncAfterReconnect || !hasSession) {
      return null;
    }
    return refreshWhoAmI();
  }

  Future<String> _refreshAccessToken({
    required List<String> scopes,
    required DateTime now,
  }) async {
    final state = _state;
    if (state == null) {
      throw const VtaAuthException(
        'No authenticated session is available.',
        code: 'e.vta.auth.session_missing',
      );
    }

    final refreshToken = state.tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      clear();
      throw const VtaAuthException(
        'Access token expired and no refresh token is available.',
        code: 'e.vta.auth.refresh_missing',
      );
    }

    final refreshExpiresAt = state.refreshExpiresAt;
    if (refreshExpiresAt != null && !refreshExpiresAt.isAfter(now)) {
      clear();
      throw const VtaAuthException(
        'Refresh token expired.',
        code: 'e.vta.auth.refresh_expired',
      );
    }

    try {
      final result = await client.auth.refresh(
        request: VtaRefreshRequest.create(
          holderDid: holderDid,
          vtaDid: vtaDid,
          refreshToken: refreshToken,
          scopes: scopes,
          issuedAt: now,
        ),
        protocol: protocol,
      );
      applyAuthenticateResult(result);
      if (shouldSyncAfterRefresh) {
        await refreshWhoAmI();
      }
      return result.tokens.accessToken;
    } on VtaAuthException catch (error) {
      if (error.statusCode == 401 || error.code == 'e.vta.auth.unauthorized') {
        clear();
      }
      rethrow;
    }
  }

  void clear() {
    _state = null;
    client.setAuthToken(null);
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
}

class _SessionState {
  const _SessionState({
    required this.tokens,
    required this.session,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  factory _SessionState.fromAuthenticateResult(VtaAuthenticateResult result) {
    return _SessionState(
      tokens: result.tokens,
      session: result.session,
      accessExpiresAt: result.accessExpiresAt.toUtc(),
      refreshExpiresAt: result.refreshExpiresAt?.toUtc(),
    );
  }

  final AuthTokens tokens;
  final SessionInfo session;
  final DateTime accessExpiresAt;
  final DateTime? refreshExpiresAt;

  _SessionState copyWith({SessionInfo? session}) {
    return _SessionState(
      tokens: tokens,
      session: session ?? this.session,
      accessExpiresAt: accessExpiresAt,
      refreshExpiresAt: refreshExpiresAt,
    );
  }
}
