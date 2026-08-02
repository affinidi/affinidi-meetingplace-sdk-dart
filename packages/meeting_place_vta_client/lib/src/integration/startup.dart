import 'dart:convert';

import '../auth/auth_api.dart';
import '../auth/auth_service.dart';
import '../auth/auth_workflow.dart';
import '../auth/auth_protocol.dart';
import '../auth/connection_coordinator.dart';
import '../auth/session_manager.dart';
import '../client/vta_client.dart';
import '../errors/vta_client_exception.dart';
import '../models/did_secrets_bundle.dart';
import '../models/vta_authenticate_result.dart';
import '../models/vta_config.dart';
import '../models/vta_credential_bundle.dart';
import '../transport/http_transport.dart';

const String _defaultSnapshotKey = 'vta.startup.snapshot.v1';

/// Abstraction for secure storage backends used by startup recovery.
///
/// Implementations should use platform secure storage (Keychain/Keystore) in
/// production and may use in-memory storage for tests.
abstract class VtaSecureStore {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

class VtaStartupSnapshot {
  const VtaStartupSnapshot({
    required this.config,
    required this.credential,
    this.didSecrets,
    this.authResult,
    required this.createdAt,
    required this.updatedAt,
  });

  final VtaConfig config;
  final VtaCredentialBundle credential;
  final DidSecretsBundle? didSecrets;
  final VtaAuthenticateResult? authResult;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get holderDid => credential.did;

  String get vtaUrl => credential.vtaUrl;

  String? get contextId => credential.contextId;

  String? get keyId => credential.keyId;

  VtaStartupSnapshot copyWith({
    VtaConfig? config,
    VtaCredentialBundle? credential,
    DidSecretsBundle? didSecrets,
    bool clearDidSecrets = false,
    VtaAuthenticateResult? authResult,
    bool clearAuthResult = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VtaStartupSnapshot(
      config: config ?? this.config,
      credential: credential ?? this.credential,
      didSecrets: clearDidSecrets ? null : (didSecrets ?? this.didSecrets),
      authResult: clearAuthResult ? null : (authResult ?? this.authResult),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  VtaStartupSnapshot withAuthResult(
    VtaAuthenticateResult? result, {
    DateTime? now,
  }) {
    return copyWith(
      authResult: result,
      clearAuthResult: result == null,
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  void validate() {
    config.validate();
    if (holderDid.trim().isEmpty) {
      throw const VtaValidationException(
        'Credential DID must be non-empty.',
        code: 'e.vta.startup.invalid_holder_did',
      );
    }
    if (vtaUrl.trim().isEmpty) {
      throw const VtaValidationException(
        'Credential vta_url must be non-empty.',
        code: 'e.vta.startup.invalid_vta_url',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'config': config.toJson(),
      'credential': credential.toJson(),
      if (didSecrets != null) 'did_secrets': didSecrets!.toJson(),
      if (authResult != null) 'auth_result': authResult!.toJson(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory VtaStartupSnapshot.fromJson(Map<String, dynamic> json) {
    final configJson = _requiredObject(json, 'config');
    final credentialJson = _requiredObject(json, 'credential');
    final didSecretsJson = _optionalObject(json, 'did_secrets');
    final authResultJson = _optionalObject(json, 'auth_result');

    return VtaStartupSnapshot(
      config: VtaConfig.fromJson(configJson),
      credential: VtaCredentialBundle.fromJson(credentialJson),
      didSecrets: didSecretsJson == null
          ? null
          : DidSecretsBundle.fromJson(didSecretsJson),
      authResult: authResultJson == null
          ? null
          : VtaAuthenticateResult.fromJson(authResultJson),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
    );
  }

  static Map<String, dynamic> _requiredObject(
    Map<String, dynamic> json,
    String key,
  ) {
    final object = _optionalObject(json, key);
    if (object != null) {
      return object;
    }
    throw VtaParseException(
      'Missing required object field "$key" in startup snapshot.',
      code: 'e.vta.startup.required_field',
    );
  }

  static Map<String, dynamic>? _optionalObject(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw VtaParseException(
      'Expected object for startup snapshot field "$key".',
      code: 'e.vta.startup.invalid_field',
    );
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw VtaParseException(
        'Missing required datetime field "$key" in startup snapshot.',
        code: 'e.vta.startup.required_field',
      );
    }
    try {
      return DateTime.parse(value).toUtc();
    } on FormatException catch (error) {
      throw VtaParseException(
        'Invalid datetime field "$key" in startup snapshot.',
        code: 'e.vta.startup.invalid_field',
        originalMessage: error.message,
      );
    }
  }
}

class VtaStartupCapability {
  VtaStartupCapability({
    required this.secureStore,
    String? snapshotKey,
    DateTime Function()? clock,
  }) : _snapshotKey = (snapshotKey == null || snapshotKey.trim().isEmpty)
           ? _defaultSnapshotKey
           : snapshotKey,
       _clock = clock ?? _defaultClock;

  final VtaSecureStore secureStore;
  final String _snapshotKey;
  final DateTime Function() _clock;

  Future<VtaStartupSnapshot> initializeFromCredentialBundle({
    required String encodedCredentialBundle,
    required VtaConfig config,
    DidSecretsBundle? didSecrets,
  }) async {
    config.validate();

    final credential = VtaCredentialBundle.parse(encodedCredentialBundle);
    if (credential.vtaUrl.trim() != config.baseUrl.trim()) {
      throw const VtaValidationException(
        'Credential bundle vta_url does not match startup config baseUrl.',
        code: 'e.vta.startup.vta_url_mismatch',
      );
    }

    final now = _clock().toUtc();
    final snapshot = VtaStartupSnapshot(
      config: config,
      credential: credential,
      didSecrets: didSecrets,
      createdAt: now,
      updatedAt: now,
    );
    snapshot.validate();
    await save(snapshot);
    return snapshot;
  }

  Future<void> save(VtaStartupSnapshot snapshot) async {
    snapshot.validate();
    final normalized = snapshot.copyWith(updatedAt: _clock().toUtc());
    final serialized = _encodeJson(normalized.toJson());

    try {
      await secureStore.write(key: _snapshotKey, value: serialized);
    } on VtaException {
      rethrow;
    } on Object catch (error) {
      throw VtaCacheException(
        'Failed to persist startup snapshot.',
        code: 'e.vta.startup.cache_write_failed',
        originalMessage: error.toString(),
      );
    }
  }

  Future<VtaStartupSnapshot?> restore() async {
    final serialized = await _readSnapshotValue();
    if (serialized == null || serialized.trim().isEmpty) {
      return null;
    }

    final decoded = _decodeJsonObject(serialized);
    final snapshot = VtaStartupSnapshot.fromJson(decoded);
    snapshot.validate();
    return snapshot;
  }

  Future<VtaStartupSnapshot> persistAuthResult({
    required VtaStartupSnapshot snapshot,
    required VtaAuthenticateResult authResult,
  }) async {
    final updated = snapshot.withAuthResult(authResult, now: _clock());
    await save(updated);
    return updated;
  }

  Future<VtaStartupSnapshot> clearAuthResult({
    required VtaStartupSnapshot snapshot,
  }) async {
    final updated = snapshot.withAuthResult(null, now: _clock());
    await save(updated);
    return updated;
  }

  VtaStartupRuntime buildAuthRuntimeFromSnapshot({
    required VtaStartupSnapshot snapshot,
    required VtaAuthProtocol protocol,
    VtaHttpTransport? transport,
    VtaAuthTransport? authTransport,
    Duration refreshSkew = const Duration(seconds: 45),
    VtaWhoAmISyncPolicy whoAmISyncPolicy =
        VtaWhoAmISyncPolicy.onRefreshOrReconnect,
    VtaReconnectPolicy reconnectPolicy = const VtaReconnectPolicy(),
    DateTime Function()? clock,
  }) {
    snapshot.validate();

    final runtimeClock = clock ?? _clock;
    final client = VtaClient(
      baseUrl: snapshot.config.baseUrl,
      transport: transport,
      authTransport: authTransport,
    );
    final sessionManager = VtaSessionManager(
      client: client,
      holderDid: snapshot.holderDid,
      vtaDid: snapshot.config.vtaDid,
      protocol: protocol,
      refreshSkew: refreshSkew,
      whoAmISyncPolicy: whoAmISyncPolicy,
      clock: runtimeClock,
    );
    hydrateSessionManager(sessionManager: sessionManager, snapshot: snapshot);

    final workflow = VtaAuthWorkflow(
      client: client,
      holderDid: snapshot.holderDid,
      vtaDid: snapshot.config.vtaDid,
      protocol: protocol,
      sessionManager: sessionManager,
    );
    final authService = workflow.authService;
    final connectionCoordinator = VtaConnectionCoordinator(
      authService: authService,
      sessionManager: sessionManager,
      reconnectPolicy: reconnectPolicy,
      clock: runtimeClock,
    );

    return VtaStartupRuntime(
      snapshot: snapshot,
      client: client,
      sessionManager: sessionManager,
      authService: authService,
      authWorkflow: workflow,
      connectionCoordinator: connectionCoordinator,
    );
  }

  Future<VtaStartupRuntime?> restoreAuthRuntime({
    required VtaAuthProtocol protocol,
    VtaHttpTransport? transport,
    VtaAuthTransport? authTransport,
    Duration refreshSkew = const Duration(seconds: 45),
    VtaWhoAmISyncPolicy whoAmISyncPolicy =
        VtaWhoAmISyncPolicy.onRefreshOrReconnect,
    VtaReconnectPolicy reconnectPolicy = const VtaReconnectPolicy(),
    DateTime Function()? clock,
  }) async {
    final snapshot = await restore();
    if (snapshot == null) {
      return null;
    }

    return buildAuthRuntimeFromSnapshot(
      snapshot: snapshot,
      protocol: protocol,
      transport: transport,
      authTransport: authTransport,
      refreshSkew: refreshSkew,
      whoAmISyncPolicy: whoAmISyncPolicy,
      reconnectPolicy: reconnectPolicy,
      clock: clock,
    );
  }

  void hydrateSessionManager({
    required VtaSessionManager sessionManager,
    required VtaStartupSnapshot snapshot,
  }) {
    final authResult = snapshot.authResult;
    if (authResult == null) {
      return;
    }
    sessionManager.applyAuthenticateResult(authResult);
  }

  Future<void> clear() async {
    try {
      await secureStore.delete(key: _snapshotKey);
    } on VtaException {
      rethrow;
    } on Object catch (error) {
      throw VtaCacheException(
        'Failed to clear startup snapshot.',
        code: 'e.vta.startup.cache_delete_failed',
        originalMessage: error.toString(),
      );
    }
  }

  Future<String?> _readSnapshotValue() async {
    try {
      return await secureStore.read(key: _snapshotKey);
    } on VtaException {
      rethrow;
    } on Object catch (error) {
      throw VtaCacheException(
        'Failed to read startup snapshot.',
        code: 'e.vta.startup.cache_read_failed',
        originalMessage: error.toString(),
      );
    }
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
}

class VtaStartupRuntime {
  const VtaStartupRuntime({
    required this.snapshot,
    required this.client,
    required this.sessionManager,
    required this.authService,
    required this.authWorkflow,
    required this.connectionCoordinator,
  });

  final VtaStartupSnapshot snapshot;
  final VtaClient client;
  final VtaSessionManager sessionManager;
  final VtaAuthService authService;
  final VtaAuthWorkflow authWorkflow;
  final VtaConnectionCoordinator connectionCoordinator;
}

class VtaInMemorySecureStore implements VtaSecureStore {
  VtaInMemorySecureStore([Map<String, String>? seed])
    : _values = <String, String>{...?seed};

  final Map<String, String> _values;

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

String _encodeJson(Map<String, dynamic> value) {
  return jsonEncode(value);
}

Map<String, dynamic> _decodeJsonObject(String source) {
  final decoded = _decodeJson(source);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  throw const VtaParseException(
    'Startup snapshot payload must decode to a JSON object.',
    code: 'e.vta.startup.invalid_payload',
  );
}

Object? _decodeJson(String source) {
  try {
    return jsonDecode(source);
  } on FormatException catch (error) {
    throw VtaParseException(
      'Startup snapshot payload is not valid JSON.',
      code: 'e.vta.startup.invalid_payload',
      originalMessage: error.message,
    );
  }
}
