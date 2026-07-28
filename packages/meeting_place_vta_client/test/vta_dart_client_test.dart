import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';
import 'package:test/test.dart';

void main() {
  group('VtaClient', () {
    test('adds bearer token and decodes JSON responses', () async {
      final transport = _FakeTransport(
        getHandler: (uri, headers) async {
          expect(uri.toString(), 'https://example.com/health');
          expect(headers['Authorization'], 'Bearer test-token');
          return VtaHttpResponse(statusCode: 200, body: '{"status":"ok"}');
        },
      );

      final client = VtaClient(
        baseUrl: 'https://example.com',
        authToken: 'test-token',
        transport: transport,
      );

      final data = await client.getJson('/health');
      expect(data['status'], 'ok');
    });

    test('throws VtaAuthException for 401 responses', () async {
      final transport = _FakeTransport(
        postHandler: (uri, headers, body) async =>
            VtaHttpResponse(statusCode: 401, body: '{"error":"unauthorized"}'),
      );

      final client = VtaClient(
        baseUrl: 'https://example.com',
        transport: transport,
      );

      expect(
        () => client.postJson('/auth', body: {'username': 'demo'}),
        throwsA(isA<VtaAuthException>()),
      );
    });
  });
}

typedef _GetHandler =
    Future<VtaHttpResponse> Function(Uri uri, Map<String, String> headers);
typedef _PostHandler =
    Future<VtaHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      Object? body,
    );

class _FakeTransport implements VtaHttpTransport {
  _FakeTransport({this.getHandler, this.postHandler});

  final _GetHandler? getHandler;
  final _PostHandler? postHandler;

  @override
  Future<VtaHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    if (getHandler == null) {
      throw StateError('No getHandler was provided for this test.');
    }
    return getHandler!(uri, headers ?? const {});
  }

  @override
  Future<VtaHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (postHandler == null) {
      throw StateError('No postHandler was provided for this test.');
    }
    return postHandler!(uri, headers ?? const {}, body);
  }

  @override
  Future<VtaHttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    throw StateError('No putHandler was provided for this test.');
  }
}
