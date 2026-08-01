import 'dart:async';
import 'dart:convert';

import '../errors/vta_client_exception.dart';
import 'transport.dart';

enum VtaMediatorSessionState { disconnected, connecting, connected, degraded }

class VtaMediatorInboundMessage {
  const VtaMediatorInboundMessage({
    required this.messageJson,
    required this.senderAuthenticated,
    this.senderDid,
    this.messageId,
    this.threadId,
    this.messageType,
  });

  final String messageJson;
  final bool senderAuthenticated;
  final String? senderDid;
  final String? messageId;
  final String? threadId;
  final String? messageType;
}

class VtaDidCommMessage {
  const VtaDidCommMessage({
    required this.id,
    required this.type,
    this.from,
    this.to,
    this.body = const <String, dynamic>{},
    this.raw,
  });

  factory VtaDidCommMessage.fromJson(Map<String, dynamic> json) {
    final body = json['body'];
    final normalizedBody = body is Map<String, dynamic>
        ? body
        : body is Map
        ? body.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return VtaDidCommMessage(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      body: normalizedBody,
      raw: json,
    );
  }

  factory VtaDidCommMessage.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) {
      return VtaDidCommMessage.fromJson(decoded);
    }
    if (decoded is Map) {
      return VtaDidCommMessage.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw const VtaParseException(
      'Expected DIDComm message JSON object.',
      code: 'e.vta.didcomm.invalid_message',
    );
  }

  final String id;
  final String type;
  final String? from;
  final String? to;
  final Map<String, dynamic> body;
  final Map<String, dynamic>? raw;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type,
    if (from != null) 'from': from,
    if (to != null) 'to': to,
    'body': body,
    ...?raw,
  };
}

abstract class VtaMediatorWireTransport {
  Future<void> open();

  Future<void> close();

  Future<void> send(String messageJson);

  Future<VtaMediatorInboundMessage?> receive({
    Duration timeout = const Duration(seconds: 30),
  });

  Future<void> acknowledge(VtaMediatorInboundMessage message);
}

class VtaMediatorProtocolConfig {
  const VtaMediatorProtocolConfig({
    this.enableHandshake = true,
    this.enablePickup = true,
    this.enableAck = true,
  });

  final bool enableHandshake;
  final bool enablePickup;
  final bool enableAck;
}

class VtaMediatorWireTransportAdapter implements VtaMediatorWireTransport {
  VtaMediatorWireTransportAdapter({
    required VtaDidCommChannel channel,
    required VtaDidCommPacker packer,
    this.protocolConfig = const VtaMediatorProtocolConfig(),
  }) : _channel = channel,
       _packer = packer;

  final VtaDidCommChannel _channel;
  final VtaDidCommPacker _packer;
  final VtaMediatorProtocolConfig protocolConfig;

  bool _mediatorAuthenticated = false;

  @override
  Future<void> close() async {
    _mediatorAuthenticated = false;
    await _channel.disconnect();
  }

  @override
  Future<void> open() async {
    await _channel.connect();
    if (protocolConfig.enableHandshake && !_mediatorAuthenticated) {
      await _sendControlMessage(
        type: 'https://didcomm.org/coordinate-mediation/3.0/mediate-request',
        body: const <String, dynamic>{},
      );
      // Consume the mediate-grant response so it doesn't leak into the
      // application-level receive stream.
      await _channel.receive(timeout: const Duration(seconds: 10));
      _mediatorAuthenticated = true;
    }
  }

  @override
  Future<VtaMediatorInboundMessage?> receive({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (protocolConfig.enablePickup) {
      await _sendControlMessage(
        type: 'https://didcomm.org/messagepickup/3.0/status-request',
        body: const <String, dynamic>{},
      );
    }

    final packed = await _channel.receive(timeout: timeout);
    if (packed == null || packed.trim().isEmpty) {
      return null;
    }

    final unpacked = await _packer.unpack(packedMessage: packed);
    return VtaMediatorInboundMessage(
      messageJson: unpacked.messageJson,
      senderAuthenticated: unpacked.senderAuthenticated,
      senderDid: unpacked.senderDid,
      messageId: unpacked.messageId,
      threadId: unpacked.threadId,
      messageType: unpacked.messageType,
    );
  }

  @override
  Future<void> send(String messageJson) async {
    final packed = await _packer.pack(
      messageJson: messageJson,
      endpoint: const VtaDidCommEndpoint(
        endpoint: '/didcomm/mediator',
        replyExpected: false,
      ),
    );
    await _channel.send(packed);
  }

  @override
  Future<void> acknowledge(VtaMediatorInboundMessage message) async {
    if (!protocolConfig.enableAck || message.messageId == null) {
      return;
    }
    await _sendControlMessage(
      type: 'https://didcomm.org/messagepickup/3.0/delivery-received',
      body: <String, dynamic>{
        'message_id_list': <String>[message.messageId!],
      },
    );
  }

  Future<void> _sendControlMessage({
    required String type,
    required Map<String, dynamic> body,
  }) async {
    final id = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    final payload = jsonEncode(
      VtaDidCommEnvelope(id: id, thid: id, type: type, body: body).toJson(),
    );
    final packed = await _packer.pack(
      messageJson: payload,
      endpoint: const VtaDidCommEndpoint(
        endpoint: '/didcomm/mediator-control',
        replyExpected: false,
      ),
    );
    await _channel.send(packed);
  }
}

class VtaMediatorSession {
  VtaMediatorSession({
    required VtaMediatorWireTransport transport,
    this.expectedSenderDid,
  }) : _transport = transport;

  final VtaMediatorWireTransport _transport;
  final String? expectedSenderDid;
  final StreamController<VtaMediatorSessionState> _stateController =
      StreamController<VtaMediatorSessionState>.broadcast();

  VtaMediatorSessionState _state = VtaMediatorSessionState.disconnected;

  VtaMediatorSessionState get state => _state;
  Stream<VtaMediatorSessionState> get stateChanges => _stateController.stream;

  Future<void> connect() async {
    _setState(VtaMediatorSessionState.connecting);
    try {
      await _transport.open();
      _setState(VtaMediatorSessionState.connected);
    } on Object {
      _setState(VtaMediatorSessionState.degraded);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _transport.close();
    } finally {
      _setState(VtaMediatorSessionState.disconnected);
    }
  }

  Future<void> send(VtaDidCommMessage message) {
    return _transport.send(jsonEncode(message.toJson()));
  }

  Future<VtaDidCommMessage?> receiveNext({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final inbound = await _transport.receive(timeout: timeout);
    if (inbound == null || inbound.messageJson.trim().isEmpty) {
      return null;
    }

    _enforceSenderAuthenticated(inbound);
    await _transport.acknowledge(inbound);

    final message = VtaDidCommMessage.fromJsonString(inbound.messageJson);
    _enforceExpectedSender(message);
    return message;
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }

  void _enforceExpectedSender(VtaDidCommMessage message) {
    final expected = expectedSenderDid;
    if (expected == null || expected.isEmpty) {
      return;
    }

    final sender = message.from;
    if (sender == null || sender != expected) {
      throw VtaProtocolException(
        'Unexpected DIDComm sender. Expected $expected, got ${sender ?? 'unknown'}',
        code: 'e.vta.didcomm.unexpected_sender',
      );
    }
  }

  void _enforceSenderAuthenticated(VtaMediatorInboundMessage message) {
    if (!message.senderAuthenticated) {
      throw const VtaProtocolException(
        'Inbound DIDComm message is not sender-authenticated.',
        code: 'e.vta.didcomm.sender_not_authenticated',
      );
    }
  }

  void _setState(VtaMediatorSessionState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    _stateController.add(next);
  }
}
