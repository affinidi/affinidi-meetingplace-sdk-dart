import '../errors/vta_client_exception.dart';
import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import 'auth_service.dart';
import 'session_manager.dart';

enum VtaConnectionState {
  disconnected,
  connecting,
  authenticated,
  refreshing,
  degraded,
  reconnecting,
}

class VtaReconnectPolicy {
  const VtaReconnectPolicy({
    this.maxAttempts = 3,
    this.initialBackoff = const Duration(milliseconds: 200),
    this.maxBackoff = const Duration(seconds: 2),
    this.backoffMultiplier = 2,
  });

  final int maxAttempts;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final int backoffMultiplier;
}

class VtaConnectionStatus {
  const VtaConnectionStatus({
    required this.state,
    this.attempt = 0,
    this.lastError,
  });

  final VtaConnectionState state;
  final int attempt;
  final VtaException? lastError;

  VtaConnectionStatus copyWith({
    VtaConnectionState? state,
    int? attempt,
    VtaException? lastError,
    bool clearError = false,
  }) {
    return VtaConnectionStatus(
      state: state ?? this.state,
      attempt: attempt ?? this.attempt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class VtaConnectionCoordinator {
  VtaConnectionCoordinator({
    required this.authService,
    required this.sessionManager,
    this.reconnectPolicy = const VtaReconnectPolicy(),
    DateTime Function()? clock,
  }) : _clock = clock ?? _defaultClock;

  final VtaAuthService authService;
  final VtaSessionManager sessionManager;
  final VtaReconnectPolicy reconnectPolicy;
  final DateTime Function() _clock;

  VtaConnectionStatus _status = const VtaConnectionStatus(
    state: VtaConnectionState.disconnected,
  );

  VtaConnectionStatus get status => _status;
  VtaConnectionState get state => _status.state;

  Future<VtaAuthenticateResult> connect({
    String? purpose,
    List<String> scopes = const <String>[],
  }) async {
    _status = _status.copyWith(
      state: VtaConnectionState.connecting,
      attempt: 0,
      clearError: true,
    );
    try {
      final result = await authService.connect(
        purpose: purpose,
        scopes: scopes,
      );
      _status = _status.copyWith(
        state: VtaConnectionState.authenticated,
        attempt: 0,
        clearError: true,
      );
      return result;
    } on VtaException catch (error) {
      _status = _status.copyWith(
        state: VtaConnectionState.degraded,
        lastError: error,
      );
      rethrow;
    }
  }

  Future<String> getValidAccessToken({
    List<String> scopes = const <String>[],
    bool reconnectIfNeeded = true,
  }) async {
    if (!sessionManager.hasSession) {
      if (!reconnectIfNeeded) {
        throw const VtaAuthException(
          'No authenticated session is available.',
          code: 'e.vta.auth.session_missing',
        );
      }
      await reconnect(scopes: scopes);
    }

    final shouldRefresh = _isRefreshRequired();
    if (shouldRefresh) {
      _status = _status.copyWith(state: VtaConnectionState.refreshing);
    }

    try {
      final token = await authService.getValidAccessToken(scopes: scopes);
      _status = _status.copyWith(
        state: VtaConnectionState.authenticated,
        attempt: 0,
        clearError: true,
      );
      return token;
    } on VtaException catch (error) {
      if (error is VtaAuthException && error.statusCode == 401) {
        authService.disconnect();
      }
      _status = _status.copyWith(
        state: VtaConnectionState.degraded,
        lastError: error,
      );
      rethrow;
    }
  }

  Future<SessionInfo> whoAmI({
    bool ensureValidAccessToken = true,
    List<String> scopes = const <String>[],
  }) async {
    try {
      final session = await authService.whoAmI(
        ensureValidAccessToken: ensureValidAccessToken,
        scopes: scopes,
      );
      _status = _status.copyWith(
        state: VtaConnectionState.authenticated,
        attempt: 0,
        clearError: true,
      );
      return session;
    } on VtaException catch (error) {
      _status = _status.copyWith(
        state: VtaConnectionState.degraded,
        lastError: error,
      );
      rethrow;
    }
  }

  Future<VtaAuthenticateResult> reconnect({
    String? purpose,
    List<String> scopes = const <String>[],
  }) async {
    var attempt = 0;
    var delay = reconnectPolicy.initialBackoff;
    VtaException? lastError;

    while (attempt < reconnectPolicy.maxAttempts) {
      attempt += 1;
      _status = _status.copyWith(
        state: VtaConnectionState.reconnecting,
        attempt: attempt,
      );

      try {
        final result = await authService.reconnect(
          purpose: purpose,
          scopes: scopes,
        );
        _status = _status.copyWith(
          state: VtaConnectionState.authenticated,
          attempt: 0,
          clearError: true,
        );
        return result;
      } on VtaTransportException catch (error) {
        lastError = error;
        if (attempt >= reconnectPolicy.maxAttempts) {
          break;
        }
        await Future<void>.delayed(delay);
        delay = _nextDelay(delay);
      } on VtaAclException catch (error) {
        _status = _status.copyWith(
          state: VtaConnectionState.degraded,
          lastError: error,
          attempt: attempt,
        );
        rethrow;
      } on VtaAuthException catch (error) {
        if (error.statusCode == 401) {
          authService.disconnect();
        }
        _status = _status.copyWith(
          state: VtaConnectionState.degraded,
          lastError: error,
          attempt: attempt,
        );
        rethrow;
      } on VtaException catch (error) {
        _status = _status.copyWith(
          state: VtaConnectionState.degraded,
          lastError: error,
          attempt: attempt,
        );
        rethrow;
      }
    }

    final exhausted =
        lastError ??
        const VtaTransportException(
          'Reconnect attempts exhausted.',
          code: 'e.vta.transport.reconnect_exhausted',
        );
    _status = _status.copyWith(
      state: VtaConnectionState.degraded,
      lastError: exhausted,
      attempt: reconnectPolicy.maxAttempts,
    );
    throw exhausted;
  }

  void disconnect() {
    authService.disconnect();
    _status = _status.copyWith(
      state: VtaConnectionState.disconnected,
      attempt: 0,
      clearError: true,
    );
  }

  Duration _nextDelay(Duration current) {
    final nextMs = current.inMilliseconds * reconnectPolicy.backoffMultiplier;
    final boundedMs = nextMs > reconnectPolicy.maxBackoff.inMilliseconds
        ? reconnectPolicy.maxBackoff.inMilliseconds
        : nextMs;
    return Duration(milliseconds: boundedMs);
  }

  bool _isRefreshRequired() {
    final expiresAt = sessionManager.accessExpiresAt;
    if (expiresAt == null) {
      return false;
    }
    return !expiresAt.isAfter(_clock().toUtc().add(sessionManager.refreshSkew));
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
}
