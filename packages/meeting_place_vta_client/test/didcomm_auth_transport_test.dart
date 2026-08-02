import 'dart:convert';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaDidCommAuthTransport', () {
    test('sends challenge through DIDComm transport', () async {
      final didcomm = _FakeDidCommTransport(
        handler: ({required endpoint, required body}) async {
          expect(endpoint, '/auth/challenge');
          final request = jsonDecode(body) as Map<String, dynamic>;
          expect(request['subject'], 'did:key:zHolder');
          return jsonEncode({
            'challenge': 'nonce-1',
            'sessionId': 'sess-1',
            'expiresAt': '2026-07-01T00:01:00Z',
          });
        },
      );
      final api = VtaAuthApi(
        transport: VtaDidCommAuthTransport(transport: didcomm),
      );

      final response = await api.challenge(
        const VtaChallengeRequest(subject: 'did:key:zHolder'),
      );

      expect(response.challenge, 'nonce-1');
      expect(response.sessionId, 'sess-1');
    });

    test('falls back to REST on DIDComm transport failures', () async {
      final didcommFirst = VtaDidCommFirstAuthTransport(
        didcomm: const _FailingDidCommAuthTransport(),
        fallback: _FakeAuthTransport(
          challengeHandler: (request) async => {
            'challenge': 'nonce-rest',
            'sessionId': 'sess-rest',
            'expiresAt': '2026-07-01T00:01:00Z',
          },
        ),
      );
      final api = VtaAuthApi(transport: didcommFirst);

      final response = await api.challenge(
        const VtaChallengeRequest(subject: 'did:key:zHolder'),
      );

      expect(response.challenge, 'nonce-rest');
      expect(response.sessionId, 'sess-rest');
    });
  });
}

typedef _DidCommHandler =
    Future<String> Function({required String endpoint, required String body});

class _FakeDidCommTransport implements VtaDidCommTransport {
  _FakeDidCommTransport({required this.handler});

  final _DidCommHandler handler;

  @override
  Future<String> send({
    required String endpoint,
    required String body,
    String contentType = 'application/json',
    Map<String, dynamic>? metadata,
  }) {
    return handler(endpoint: endpoint, body: body);
  }
}

class _FakeAuthTransport implements VtaAuthTransport {
  _FakeAuthTransport({this.challengeHandler})
    : whoAmIHandler = null,
      authenticateHandler = null,
      refreshHandler = null;

  final Future<Map<String, dynamic>> Function(VtaChallengeRequest request)?
  challengeHandler;
  final Future<String> Function(String document)? authenticateHandler;
  final Future<String> Function(String document)? refreshHandler;
  final Future<String> Function(String document)? whoAmIHandler;

  @override
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request) {
    if (challengeHandler == null) {
      throw UnimplementedError('challengeHandler is not set');
    }
    return challengeHandler!(request);
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) {
    if (authenticateHandler == null) {
      throw UnimplementedError('authenticateHandler is not set');
    }
    return authenticateHandler!(trustTaskDocument);
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) {
    if (refreshHandler == null) {
      throw UnimplementedError('refreshHandler is not set');
    }
    return refreshHandler!(trustTaskDocument);
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) {
    if (whoAmIHandler == null) {
      throw UnimplementedError('whoAmIHandler is not set');
    }
    return whoAmIHandler!(trustTaskDocument);
  }
}

class _FailingDidCommAuthTransport implements VtaAuthTransport {
  const _FailingDidCommAuthTransport();

  Never _fail() {
    throw const VtaTransportException(
      'DIDComm transport unavailable.',
      code: 'e.test.didcomm.unavailable',
    );
  }

  @override
  Future<Map<String, dynamic>> postChallenge(
    VtaChallengeRequest request,
  ) async {
    _fail();
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) async {
    _fail();
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) async {
    _fail();
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) async {
    _fail();
  }
}
