import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/vta_client_exception.dart';

/// Transport contract used by [VtaClient] to execute HTTP requests.
abstract class VtaHttpTransport {
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers});

  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  });
}

/// Response wrapper for transport implementations.
class VtaHttpResponse {
  VtaHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  dynamic decodeJson() {
    if (body.isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }
}

class DefaultHttpTransport implements VtaHttpTransport {
  DefaultHttpTransport({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(uri, headers: headers);
      return VtaHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on SocketException catch (error) {
      throw VtaTransportException(
        'Network failure while sending GET request.',
        code: 'e.vta.transport.network',
        originalMessage: error.message,
      );
    } on http.ClientException catch (error) {
      throw VtaTransportException(
        'HTTP client failure while sending GET request.',
        code: 'e.vta.transport.http_client',
        originalMessage: error.message,
      );
    }
  }

  @override
  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await _client.post(uri, headers: headers, body: body);
      return VtaHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on SocketException catch (error) {
      throw VtaTransportException(
        'Network failure while sending POST request.',
        code: 'e.vta.transport.network',
        originalMessage: error.message,
      );
    } on http.ClientException catch (error) {
      throw VtaTransportException(
        'HTTP client failure while sending POST request.',
        code: 'e.vta.transport.http_client',
        originalMessage: error.message,
      );
    }
  }

  @override
  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await _client.put(uri, headers: headers, body: body);
      return VtaHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on SocketException catch (error) {
      throw VtaTransportException(
        'Network failure while sending PUT request.',
        code: 'e.vta.transport.network',
        originalMessage: error.message,
      );
    } on http.ClientException catch (error) {
      throw VtaTransportException(
        'HTTP client failure while sending PUT request.',
        code: 'e.vta.transport.http_client',
        originalMessage: error.message,
      );
    }
  }
}
