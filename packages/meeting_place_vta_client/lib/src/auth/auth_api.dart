import 'dart:convert';

import '../client/vta_client.dart';
import '../didcomm/transport.dart';
import '../errors/vta_client_exception.dart';
import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import '../models/vta_challenge_response.dart';
import 'auth_models.dart';
import 'auth_protocol.dart';

abstract class VtaAuthTransport {
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request);

  Future<String> postAuthenticate(String trustTaskDocument);

  Future<String> postRefresh(String trustTaskDocument);

  Future<String> postWhoAmI(String trustTaskDocument);
}

class VtaRestAuthTransport implements VtaAuthTransport {
  const VtaRestAuthTransport(this._client);

  final VtaClient _client;

  @override
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request) {
    return _client.postJson('/auth/challenge', body: request.toJson());
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) {
    return _client.postText('/auth/', body: trustTaskDocument);
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) {
    return _client.postText('/auth/refresh', body: trustTaskDocument);
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) {
    return _client.postText('/api/trust-tasks', body: trustTaskDocument);
  }
}

class VtaDeferredClientAuthTransport implements VtaAuthTransport {
  const VtaDeferredClientAuthTransport(this._clientProvider);

  final VtaClient Function() _clientProvider;

  VtaAuthTransport get _delegate => VtaRestAuthTransport(_clientProvider());

  @override
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request) {
    return _delegate.postChallenge(request);
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) {
    return _delegate.postAuthenticate(trustTaskDocument);
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) {
    return _delegate.postRefresh(trustTaskDocument);
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) {
    return _delegate.postWhoAmI(trustTaskDocument);
  }
}

class VtaDidCommAuthTransport implements VtaAuthTransport {
  const VtaDidCommAuthTransport({required this._transport});

  final VtaDidCommTransport _transport;

  @override
  Future<Map<String, dynamic>> postChallenge(
    VtaChallengeRequest request,
  ) async {
    final responseBody = await _transport.send(
      endpoint: '/auth/challenge',
      body: _encodeJson(request.toJson()),
      contentType: 'application/json',
    );
    return _decodeObject(responseBody, field: 'challengeResponse');
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) {
    return _transport.send(
      endpoint: '/auth/',
      body: trustTaskDocument,
      contentType: 'application/json',
    );
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) {
    return _transport.send(
      endpoint: '/auth/refresh',
      body: trustTaskDocument,
      contentType: 'application/json',
    );
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) {
    return _transport.send(
      endpoint: '/api/trust-tasks',
      body: trustTaskDocument,
      contentType: 'application/json',
    );
  }

  String _encodeJson(Map<String, dynamic> value) {
    return jsonEncode(value);
  }

  Map<String, dynamic> _decodeObject(String body, {required String field}) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw VtaParseException(
      'Expected JSON object for $field.',
      code: 'e.vta.didcomm.invalid_response',
    );
  }
}

class VtaDidCommFallbackPolicy {
  const VtaDidCommFallbackPolicy({
    this.enableRestFallback = true,
    this.fallbackOnTransportError = true,
    this.fallbackOnProtocolError = true,
  });

  final bool enableRestFallback;
  final bool fallbackOnTransportError;
  final bool fallbackOnProtocolError;

  bool shouldFallbackFor(Object error) {
    if (!enableRestFallback) {
      return false;
    }
    if (fallbackOnTransportError && error is VtaTransportException) {
      return true;
    }
    if (fallbackOnProtocolError && error is VtaProtocolException) {
      return true;
    }
    return false;
  }
}

class VtaDidCommFirstAuthTransport implements VtaAuthTransport {
  const VtaDidCommFirstAuthTransport({
    VtaAuthTransport? didcomm,
    required this.fallback,
    this.policy = const VtaDidCommFallbackPolicy(),
    this.onFallback,
  }) : didcomm = didcomm ?? fallback;

  final VtaAuthTransport didcomm;
  final VtaAuthTransport fallback;
  final VtaDidCommFallbackPolicy policy;
  final void Function(Object error)? onFallback;

  @override
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request) {
    return _execute((transport) => transport.postChallenge(request));
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) {
    return _execute(
      (transport) => transport.postAuthenticate(trustTaskDocument),
    );
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) {
    return _execute((transport) => transport.postRefresh(trustTaskDocument));
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) {
    return _execute((transport) => transport.postWhoAmI(trustTaskDocument));
  }

  Future<T> _execute<T>(
    Future<T> Function(VtaAuthTransport transport) call,
  ) async {
    try {
      return await call(didcomm);
    } catch (error) {
      if (policy.shouldFallbackFor(error)) {
        onFallback?.call(error);
        return call(fallback);
      }
      rethrow;
    }
  }
}

class VtaAuthApi {
  VtaAuthApi({required this._transport});

  final VtaAuthTransport _transport;

  Future<VtaChallengeResponse> challenge(VtaChallengeRequest request) async {
    request.validate();
    final response = await _transport.postChallenge(request);
    return VtaChallengeResponse.fromJson(response);
  }

  Future<VtaAuthenticateResult> authenticate({
    required VtaAuthenticateRequest request,
    required VtaAuthProtocol protocol,
  }) async {
    request.validate();
    final document = await protocol.buildAuthenticateDocument(request);
    final responseBody = await _transport.postAuthenticate(document);
    return protocol.parseAuthenticateResponse(responseBody);
  }

  Future<VtaAuthenticateResult> refresh({
    required VtaRefreshRequest request,
    required VtaAuthProtocol protocol,
  }) async {
    request.validate();
    final document = await protocol.buildRefreshDocument(request);
    final responseBody = await _transport.postRefresh(document);
    return protocol.parseRefreshResponse(responseBody);
  }

  Future<SessionInfo> whoAmI({
    required VtaWhoAmIRequest request,
    required VtaAuthProtocol protocol,
  }) async {
    request.validate();
    final document = await protocol.buildWhoAmIDocument(request);
    final responseBody = await _transport.postWhoAmI(document);
    return protocol.parseWhoAmIResponse(responseBody);
  }
}
