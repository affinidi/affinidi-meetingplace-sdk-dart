import 'dart:async';
import 'dart:collection';

import 'package:test/test.dart';
import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  group('VtaDidCommStepUp', () {
    test('extracts approve-request from DIDComm body', () {
      const message =
          '{"id":"m1","type":"https://didcomm.org/message/2.0","body":{"type":"https://trusttasks.org/spec/auth/step-up/approve-request/0.1","sessionId":"sess-1"}}';

      final request = VtaDidCommStepUp.extractApproveRequest(message);

      expect(request, isNotNull);
      expect(request!['sessionId'], 'sess-1');
    });

    test('returns null for non step-up message', () {
      const message =
          '{"id":"m1","type":"https://didcomm.org/message/2.0","body":{"type":"https://trusttasks.org/spec/auth/whoami/0.1"}}';

      final request = VtaDidCommStepUp.extractApproveRequest(message);

      expect(request, isNull);
    });
  });

  group('VtaMediatorSession', () {
    test('connects and receives message from expected sender', () async {
      final transport = _FakeMediatorWireTransport(
        messages: <String>[
          '{"id":"m1","type":"didcomm","from":"did:webvh:vta.example","body":{"hello":"world"}}',
        ],
      );
      final session = VtaMediatorSession(
        transport: transport,
        expectedSenderDid: 'did:webvh:vta.example',
      );

      await session.connect();
      final message = await session.receiveNext();

      expect(session.state, VtaMediatorSessionState.connected);
      expect(message, isNotNull);
      expect(message!.body['hello'], 'world');
      await session.dispose();
    });

    test('throws when sender does not match expected DID', () async {
      final transport = _FakeMediatorWireTransport(
        messages: <String>[
          '{"id":"m1","type":"didcomm","from":"did:key:zOther","body":{}}',
        ],
      );
      final session = VtaMediatorSession(
        transport: transport,
        expectedSenderDid: 'did:webvh:vta.example',
      );

      await session.connect();
      await expectLater(
        session.receiveNext(),
        throwsA(isA<VtaProtocolException>()),
      );
      await session.dispose();
    });

    test('throws when inbound message is not sender-authenticated', () async {
      final transport = _FakeMediatorWireTransport(
        messages: <String>[
          '{"id":"m1","type":"didcomm","from":"did:webvh:vta.example","body":{}}',
        ],
        senderAuthenticated: false,
      );
      final session = VtaMediatorSession(
        transport: transport,
        expectedSenderDid: 'did:webvh:vta.example',
      );

      await session.connect();
      await expectLater(
        session.receiveNext(),
        throwsA(
          isA<VtaProtocolException>().having(
            (error) => error.code,
            'code',
            'e.vta.didcomm.sender_not_authenticated',
          ),
        ),
      );
      await session.dispose();
    });
  });

  group('VtaStepUpApprovalCoordinator', () {
    test('auto-approves step-up approve-request messages', () async {
      final transport = _FakeMediatorWireTransport(
        messages: <String>[
          '{"id":"m1","type":"didcomm","from":"did:webvh:vta.example","body":{"type":"https://trusttasks.org/spec/auth/step-up/approve-request/0.1","sessionId":"sess-1","subject":"did:key:zHolder","challenge":"nonce-1"}}',
        ],
      );
      final session = VtaMediatorSession(
        transport: transport,
        expectedSenderDid: 'did:webvh:vta.example',
      );
      await session.connect();

      final coordinator = VtaStepUpApprovalCoordinator(
        mediatorSession: session,
        approvalOperation: VtaStepUpApprovalOperation(
          holderDid: 'did:key:zHolder',
          vtaDid: 'did:webvh:vta.example',
          signer: const _NoopSigner(),
          submit: (document) async =>
              '{"payload":{"session":{"session_id":"sess-1","acr":"aal2"}}}',
        ),
        onApproveRequest: (approveRequest, message) async {
          return VtaStepUpApprovalDecision(approved: true);
        },
      );

      final event = await coordinator.processOnce();

      expect(event, isNotNull);
      expect(event!.status, VtaStepUpApprovalStatus.approved);
      expect(event.approveRequest?['sessionId'], 'sess-1');
      expect(event.approvalResult?.grantedAcr, 'aal2');

      await coordinator.dispose();
      await session.dispose();
    });
  });
}

class _FakeMediatorWireTransport implements VtaMediatorWireTransport {
  _FakeMediatorWireTransport({
    List<String>? messages,
    this.senderAuthenticated = true,
  }) : _queue = Queue<String>.from(messages ?? const <String>[]);

  final Queue<String> _queue;
  final List<String> sentMessages = <String>[];
  final bool senderAuthenticated;
  bool _open = false;

  @override
  Future<void> close() async {
    _open = false;
  }

  @override
  Future<void> open() async {
    _open = true;
  }

  @override
  Future<VtaMediatorInboundMessage?> receive({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_open || _queue.isEmpty) {
      return null;
    }
    final messageJson = _queue.removeFirst();
    return VtaMediatorInboundMessage(
      messageJson: messageJson,
      senderAuthenticated: senderAuthenticated,
      senderDid: 'did:webvh:vta.example',
      messageId: 'm1',
    );
  }

  @override
  Future<void> send(String messageJson) async {
    if (!_open) {
      throw StateError('transport is closed');
    }
    sentMessages.add(messageJson);
  }

  @override
  Future<void> acknowledge(VtaMediatorInboundMessage message) async {}
}

class _NoopSigner implements VtaAuthSigner {
  const _NoopSigner();

  @override
  Future<Map<String, dynamic>> createProof({
    required Map<String, dynamic> trustTask,
    required String operation,
  }) async {
    return const <String, dynamic>{'type': 'DataIntegrityProof'};
  }
}
