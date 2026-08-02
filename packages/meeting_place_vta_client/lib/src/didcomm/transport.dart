import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../errors/vta_client_exception.dart';

/// Ensures a mediator URL has the correct WebSocket scheme (ws:// or wss://).
/// Converts http:// → ws:// and https:// → wss://.
/// Handles both bare host URLs and full mediator endpoint paths.
Uri ensureWebSocketMediatorUri(String mediatorUrl) {
  var uri = Uri.parse(mediatorUrl.trim());

  // Convert HTTP schemes to WebSocket schemes
  if (uri.scheme == 'http') {
    uri = uri.replace(scheme: 'ws');
  } else if (uri.scheme == 'https') {
    uri = uri.replace(scheme: 'wss');
  }

  // Remove fragments because websocket endpoint matching is path-based.
  if (uri.hasFragment) {
    uri = uri.replace(fragment: '');
  }

  // Normalize common mediator endpoint forms to websocket path.
  final path = uri.path;
  if (path.isEmpty || path == '/') {
    uri = uri.replace(path: '/didcomm/ws');
  } else if (path == '/didcomm') {
    uri = uri.replace(path: '/didcomm/ws');
  } else if (path == '/didcomm/') {
    uri = uri.replace(path: '/didcomm/ws');
  } else if (path.endsWith('/didcomm')) {
    uri = uri.replace(path: '$path/ws');
  } else if (path.endsWith('/didcomm/')) {
    uri = uri.replace(path: '${path}ws');
  }

  return uri;
}

abstract class VtaDidCommTransport {
  Future<String> send({
    required String endpoint,
    required String body,
    String contentType = 'application/json',
    Map<String, dynamic>? metadata,
  });
}

class VtaDidCommUnpackResult {
  const VtaDidCommUnpackResult({
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

class VtaDidCommEnvelope {
  const VtaDidCommEnvelope({
    required this.id,
    this.thid,
    required this.type,
    this.from,
    this.to,
    this.body = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String? thid;
  final String type;
  final String? from;
  final String? to;
  final Map<String, dynamic> body;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    if (thid != null) 'thid': thid,
    'type': type,
    if (from != null) 'from': from,
    if (to != null) 'to': to,
    'body': body,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

class VtaDidCommEndpoint {
  const VtaDidCommEndpoint({
    required this.endpoint,
    this.messageType,
    this.replyExpected = true,
  });

  final String endpoint;
  final String? messageType;
  final bool replyExpected;

  Map<String, dynamic> toMetadata() => <String, dynamic>{
    if (messageType != null) 'messageType': messageType,
    'replyExpected': replyExpected,
  };
}

abstract class VtaDidCommPacker {
  Future<String> pack({
    required String messageJson,
    required VtaDidCommEndpoint endpoint,
  });

  Future<VtaDidCommUnpackResult> unpack({required String packedMessage});
}

abstract class VtaDidCommChannel {
  Future<void> connect();

  Future<void> disconnect();

  Future<void> send(String packedMessage);

  Future<String?> receive({Duration timeout = const Duration(seconds: 15)});
}

class VtaWebSocketMediatorChannel implements VtaDidCommChannel {
  VtaWebSocketMediatorChannel({required this.uri});

  final Uri uri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<String> _incoming =
      StreamController<String>.broadcast();
  bool _connected = false;
  VtaTransportException? _permanentFailure;

  @override
  Future<void> connect() async {
    if (_permanentFailure != null) {
      throw _permanentFailure!;
    }
    if (_connected) {
      return;
    }

    Object? lastError;
    for (final candidate in _connectionCandidates(uri)) {
      try {
        final channel = WebSocketChannel.connect(candidate);
        // Await the ready future so WS upgrade errors surface immediately.
        await channel.ready;
        _channel = channel;
        _subscription = channel.stream.listen(
          (dynamic event) {
            _incoming.add(event.toString());
          },
          onError: (Object error) {
            final ex = VtaTransportException(
              'DIDComm websocket receive failure.',
              code: 'e.vta.didcomm.websocket_receive_failed',
              originalMessage: error.toString(),
            );
            _permanentFailure = ex;
            _connected = false;
            _incoming.addError(ex);
          },
          onDone: () {
            _connected = false;
          },
        );
        _connected = true;
        return;
      } on Object catch (error) {
        lastError = error;
      }
    }

    final ex = VtaTransportException(
      'Failed to connect DIDComm websocket channel.',
      code: 'e.vta.didcomm.websocket_connect_failed',
      originalMessage: lastError?.toString() ?? 'unknown websocket failure',
    );
    _permanentFailure = ex;
    throw ex;
  }

  List<Uri> _connectionCandidates(Uri initial) {
    final candidates = <Uri>[initial];
    final path = initial.path;

    // Some mediators advertise /ws as the canonical websocket endpoint.
    if (path == '/didcomm' || path == '/didcomm/' || path == '/didcomm/ws') {
      final wsUri = initial.replace(path: '/ws');
      if (!candidates.contains(wsUri)) {
        candidates.add(wsUri);
      }
    }

    return candidates;
  }

  @override
  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null;
    _connected = false;
    _permanentFailure = null;

    await _subscription?.cancel();
    _subscription = null;
    await channel?.sink.close();
  }

  @override
  Future<String?> receive({Duration timeout = const Duration(seconds: 15)}) {
    if (_permanentFailure != null) {
      throw _permanentFailure!;
    }
    if (!_connected) {
      throw const VtaTransportException(
        'DIDComm websocket channel is not connected.',
        code: 'e.vta.didcomm.channel_disconnected',
      );
    }

    return _incoming.stream.first
        .timeout(timeout)
        .then<String?>((value) {
          return value;
        })
        .catchError((Object error) {
          if (error is TimeoutException) {
            return null;
          }
          throw error;
        });
  }

  @override
  Future<void> send(String packedMessage) async {
    if (_permanentFailure != null) {
      throw _permanentFailure!;
    }
    if (!_connected) {
      throw const VtaTransportException(
        'DIDComm websocket channel is not connected.',
        code: 'e.vta.didcomm.channel_disconnected',
      );
    }

    try {
      _channel?.sink.add(packedMessage);
    } on Object catch (error) {
      throw VtaTransportException(
        'Failed sending DIDComm websocket message.',
        code: 'e.vta.didcomm.websocket_send_failed',
        originalMessage: error.toString(),
      );
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _incoming.close();
  }
}

class VtaDidCommTransportAdapter implements VtaDidCommTransport {
  VtaDidCommTransportAdapter({
    required VtaDidCommChannel channel,
    required VtaDidCommPacker packer,
    this.responseTimeout = const Duration(seconds: 20),
  }) : _channel = channel,
       _packer = packer;

  final VtaDidCommChannel _channel;
  final VtaDidCommPacker _packer;
  final Duration responseTimeout;

  @override
  Future<String> send({
    required String endpoint,
    required String body,
    String contentType = 'application/json',
    Map<String, dynamic>? metadata,
  }) async {
    final endpointInfo = VtaDidCommEndpoint(
      endpoint: endpoint,
      messageType: metadata?['messageType']?.toString(),
      replyExpected: metadata?['replyExpected'] as bool? ?? true,
    );

    final requestId = _requestId();
    final envelope = VtaDidCommEnvelope(
      id: requestId,
      thid: requestId,
      type: endpointInfo.messageType ?? 'https://didcomm.org/message/2.0',
      body: _decodeBodyOrWrap(body, contentType: contentType),
      metadata: <String, dynamic>{
        'endpoint': endpoint,
        'contentType': contentType,
        ...endpointInfo.toMetadata(),
        ...?metadata,
      },
    );

    final plaintext = jsonEncode(envelope.toJson());
    final packed = await _packer.pack(
      messageJson: plaintext,
      endpoint: endpointInfo,
    );

    await _channel.connect();
    await _channel.send(packed);

    if (!endpointInfo.replyExpected) {
      return '';
    }

    final response = await _receiveCorrelatedReply(thid: requestId);
    if (response == null || response.messageJson.trim().isEmpty) {
      throw const VtaTransportException(
        'Timed out waiting for DIDComm response.',
        code: 'e.vta.didcomm.response_timeout',
      );
    }

    return response.messageJson;
  }

  Future<VtaDidCommUnpackResult?> _receiveCorrelatedReply({
    required String thid,
  }) async {
    final startedAt = DateTime.now().toUtc();

    while (true) {
      final elapsed = DateTime.now().toUtc().difference(startedAt);
      if (elapsed >= responseTimeout) {
        return null;
      }
      final remaining = responseTimeout - elapsed;

      final packedReply = await _channel.receive(timeout: remaining);
      if (packedReply == null || packedReply.trim().isEmpty) {
        return null;
      }
      final unpacked = await _packer.unpack(packedMessage: packedReply);

      final decoded = _decodeObject(unpacked.messageJson);
      final replyThid = decoded?['thid']?.toString();
      final replyId = decoded?['id']?.toString();
      if ((replyThid == null && replyId == null) ||
          replyThid == thid ||
          replyId == thid) {
        return unpacked;
      }
    }
  }

  Map<String, dynamic> _decodeBodyOrWrap(
    String body, {
    required String contentType,
  }) {
    if (contentType == 'application/json') {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return <String, dynamic>{'payload': decoded};
      } on FormatException {
        return <String, dynamic>{'payload': body};
      }
    }
    return <String, dynamic>{'payload': body};
  }

  String _requestId() {
    return DateTime.now().toUtc().microsecondsSinceEpoch.toString();
  }

  Map<String, dynamic>? _decodeObject(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, inner) => MapEntry(key.toString(), inner));
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
