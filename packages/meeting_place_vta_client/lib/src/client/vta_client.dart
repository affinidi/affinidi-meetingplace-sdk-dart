import 'dart:convert';

import '../auth/auth_api.dart';
import '../errors/vta_client_exception.dart';
import '../transport/http_transport.dart';
import 'audit_api.dart';
import 'step_up_policy_api.dart';
import 'vault_api.dart';

class VtaClient {
  VtaClient({
    required String baseUrl,
    this.authToken,
    VtaHttpTransport? transport,
    VtaAuthTransport? authTransport,
  }) : _baseUri = Uri.parse(baseUrl),
       _transport = transport ?? DefaultHttpTransport() {
    auth = VtaAuthApi(transport: authTransport ?? VtaRestAuthTransport(this));
    stepUpPolicy = VtaStepUpPolicyApi(client: this);
    auditLog = VtaAuditApi(client: this);
    vault = VtaVaultApi(client: this);
  }

  final Uri _baseUri;
  final VtaHttpTransport _transport;
  late final VtaAuthApi auth;
  late final VtaStepUpPolicyApi stepUpPolicy;
  late final VtaAuditApi auditLog;
  late final VtaVaultApi vault;

  String? authToken;

  void setAuthToken(String? token) {
    authToken = token;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final body = await getText(
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
    return _decodeTextOrThrow(body);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final responseBody = await postText(
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
    return _decodeTextOrThrow(responseBody);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final responseBody = await putText(
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
    return _decodeTextOrThrow(responseBody);
  }

  Future<String> getText(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path, queryParameters: queryParameters);
    final response = await _transport.get(uri, headers: _headers(headers));
    _throwIfError(response);
    return response.body;
  }

  Future<String> postText(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path, queryParameters: queryParameters);
    final encodedBody = _encodeBody(body);
    final response = await _transport.post(
      uri,
      headers: _headers(headers),
      body: encodedBody,
    );
    _throwIfError(response);
    return response.body;
  }

  Future<String> putText(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path, queryParameters: queryParameters);
    final encodedBody = _encodeBody(body);
    final response = await _transport.put(
      uri,
      headers: _headers(headers),
      body: encodedBody,
    );
    _throwIfError(response);
    return response.body;
  }

  Uri _resolve(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final mergedPath = '${_baseUri.path}$normalizedPath';
    return _baseUri.replace(
      path: mergedPath.replaceAll('//', '/'),
      queryParameters: queryParameters?.isNotEmpty == true
          ? queryParameters
          : null,
    );
  }

  Map<String, String> _headers(Map<String, String>? extraHeaders) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String) {
      return body;
    }
    return jsonEncode(body);
  }

  void _throwIfError(VtaHttpResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw VtaAuthException(
          'VTA request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
          code: 'e.vta.auth.unauthorized',
        );
      }
      if (response.statusCode == 403) {
        throw VtaAclException(
          'VTA request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
          code: 'e.vta.auth.forbidden',
        );
      }
      throw VtaClientException(
        'VTA request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
        code: 'e.vta.protocol.http_error',
      );
    }
  }

  Map<String, dynamic> _decodeTextOrThrow(String body) {
    if (body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw VtaClientException(
      'Expected JSON object response from VTA API.',
      code: 'e.vta.parse.invalid_json_object',
    );
  }
}
