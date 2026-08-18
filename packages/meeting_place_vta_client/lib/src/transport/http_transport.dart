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

  static const bool _persistentConnection = false;

  final http.Client _client;

  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final request = http.Request('GET', uri)
        ..persistentConnection = _persistentConnection;
      if (headers != null && headers.isNotEmpty) {
        request.headers.addAll(headers);
      }

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
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
      final request = http.Request('POST', uri)
        ..persistentConnection = _persistentConnection;
      if (headers != null && headers.isNotEmpty) {
        request.headers.addAll(headers);
      }
      _applyRequestBody(request, body);

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
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

  void _applyRequestBody(http.Request request, Object? body) {
    if (body == null) {
      return;
    }
    if (body is String) {
      request.body = body;
      return;
    }
    if (body is List<int>) {
      request.bodyBytes = body;
      return;
    }
    if (body is Map<String, String>) {
      request.bodyFields = body;
      return;
    }
    throw ArgumentError.value(
      body,
      'body',
      'POST body must be a String, List<int>, or Map<String, String>.',
    );
  }

  @override
  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final request = http.Request('PUT', uri)
        ..persistentConnection = _persistentConnection;
      if (headers != null && headers.isNotEmpty) {
        request.headers.addAll(headers);
      }
      _applyRequestBody(request, body);

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
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
