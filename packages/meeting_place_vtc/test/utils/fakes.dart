import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

/// A request the [FakeHttpAdapter] received.
class RecordedRequest {
  RecordedRequest(this.options, this.body);

  final RequestOptions options;
  final Map<String, dynamic> body;
}

/// Answers each request with the next queued `(status, body)` pair and
/// records what was sent.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<(int, Object?)> answers = [];

  /// Answers from the request body instead of [answers], when set.
  Future<(int, Object?)> Function(Map<String, dynamic> body)? handler;
  final List<RecordedRequest> requests = [];
  DioExceptionType? failWith;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    requests.add(
      RecordedRequest(
        options,
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      ),
    );

    if (failWith case final type?) {
      throw DioException(requestOptions: options, type: type);
    }
    final (status, body) = handler != null
        ? await handler!(requests.last.body)
        : answers.removeAt(0);
    return ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Resolves DIDs from a fixed set of documents, then from `did:key`.
class FakeDidResolver implements DidResolver {
  FakeDidResolver([Map<String, DidDocument>? documents])
    : documents = documents ?? {};

  final Map<String, DidDocument> documents;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final document = documents[did];
    if (document != null) return document;
    if (did.startsWith('did:key:')) return DidKey.resolve(did);
    throw StateError('unknown DID');
  }
}
