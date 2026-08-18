import 'package:http/http.dart' as http;
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultHttpTransport', () {
    test('applies persistentConnection to GET requests', () async {
      final client = _RecordingClient();
      final transport = DefaultHttpTransport(client: client);

      await transport.get(Uri.parse('https://example.com/health'));

      expect(client.lastRequest, isA<http.Request>());
      final request = client.lastRequest! as http.Request;
      expect(request.method, 'GET');
      expect(request.persistentConnection, isFalse);
    });

    test('applies persistentConnection to POST requests', () async {
      final client = _RecordingClient();
      final transport = DefaultHttpTransport(client: client);

      await transport.post(
        Uri.parse('https://example.com/api/trust-tasks'),
        headers: const {'Content-Type': 'application/json'},
        body: '{"doc":"value"}',
      );

      expect(client.lastRequest, isA<http.Request>());
      final request = client.lastRequest! as http.Request;
      expect(request.method, 'POST');
      expect(request.persistentConnection, isFalse);
      expect(request.body, '{"doc":"value"}');
    });

    test('applies persistentConnection to PUT requests', () async {
      final client = _RecordingClient();
      final transport = DefaultHttpTransport(client: client);

      await transport.put(
        Uri.parse('https://example.com/profile'),
        headers: const {'Content-Type': 'application/json'},
        body: '{"name":"value"}',
      );

      expect(client.lastRequest, isA<http.Request>());
      final request = client.lastRequest! as http.Request;
      expect(request.method, 'PUT');
      expect(request.persistentConnection, isFalse);
      expect(request.body, '{"name":"value"}');
    });
  });
}

class _RecordingClient extends http.BaseClient {
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream<List<int>>.value('{}'.codeUnits),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
