import 'dart:collection';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaDidCommTransportAdapter', () {
    test('packs/sends/unpacks via channel', () async {
      final channel = _FakeDidCommChannel(
        inboundMessages: <String>[
          '{"payload":{"challenge":"nonce-1","sessionId":"sess-1","expiresAt":"2026-07-01T00:01:00Z"}}',
        ],
      );
      final adapter = VtaDidCommTransportAdapter(
        channel: channel,
        packer: const _PassthroughDidCommPacker(),
      );
      final transport = VtaDidCommAuthTransport(transport: adapter);

      final response = await transport.postChallenge(
        const VtaChallengeRequest(subject: 'did:key:zHolder'),
      );

      expect(response['challenge'], 'nonce-1');
      expect(response['sessionId'], 'sess-1');
      expect(channel.sentMessages.length, 1);
    });

    test('DIDComm-first falls back to REST and emits callback', () async {
      Object? fallbackError;
      final didcomm = VtaDidCommFirstAuthTransport(
        didcomm: const _FailingDidCommAuthTransport(),
        fallback: _FakeAuthTransport(
          challengeHandler: (request) async => <String, dynamic>{
            'challenge': 'nonce-rest',
            'sessionId': 'sess-rest',
            'expiresAt': '2026-07-01T00:01:00Z',
          },
        ),
        onFallback: (error) {
          fallbackError = error;
        },
      );

      final response = await didcomm.postChallenge(
        const VtaChallengeRequest(subject: 'did:key:zHolder'),
      );

      expect(response['challenge'], 'nonce-rest');
      expect(fallbackError, isA<VtaTransportException>());
    });
  });
}

class _PassthroughDidCommPacker implements VtaDidCommPacker {
  const _PassthroughDidCommPacker();

  @override
  Future<String> pack({
    required String messageJson,
    required VtaDidCommEndpoint endpoint,
  }) async {
    return messageJson;
  }

  @override
  Future<VtaDidCommUnpackResult> unpack({required String packedMessage}) async {
    final decoded = jsonDecode(packedMessage);
    if (decoded is! Map) {
      return VtaDidCommUnpackResult(
        messageJson: packedMessage,
        senderAuthenticated: false,
      );
    }

    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    return VtaDidCommUnpackResult(
      messageJson: jsonEncode(map),
      senderAuthenticated: map['senderAuthenticated'] as bool? ?? false,
      senderDid: map['from']?.toString(),
      messageId: map['id']?.toString(),
      threadId: map['thid']?.toString(),
      messageType: map['type']?.toString(),
    );
  }
}

class _FakeDidCommChannel implements VtaDidCommChannel {
  _FakeDidCommChannel({List<String>? inboundMessages})
    : _inbound = Queue<String>.from(inboundMessages ?? const <String>[]);

  final Queue<String> _inbound;
  final List<String> sentMessages = <String>[];
  bool _connected = false;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<String?> receive({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!_connected || _inbound.isEmpty) {
      return null;
    }

    final encoded = _inbound.removeFirst();
    final payload = jsonDecode(encoded) as Map<String, dynamic>;
    return jsonEncode(payload['payload']);
  }

  @override
  Future<void> send(String packedMessage) async {
    if (!_connected) {
      throw const VtaTransportException(
        'not connected',
        code: 'e.test.didcomm.not_connected',
      );
    }
    sentMessages.add(packedMessage);
  }
}

class _FakeAuthTransport implements VtaAuthTransport {
  _FakeAuthTransport({this.challengeHandler});

  final Future<Map<String, dynamic>> Function(VtaChallengeRequest request)?
  challengeHandler;

  @override
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request) {
    if (challengeHandler == null) {
      throw UnimplementedError('challengeHandler is not set');
    }
    return challengeHandler!(request);
  }

  @override
  Future<String> postAuthenticate(String trustTaskDocument) {
    throw UnimplementedError();
  }

  @override
  Future<String> postRefresh(String trustTaskDocument) {
    throw UnimplementedError();
  }

  @override
  Future<String> postWhoAmI(String trustTaskDocument) {
    throw UnimplementedError();
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
  Future<Map<String, dynamic>> postChallenge(VtaChallengeRequest request) async {
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
