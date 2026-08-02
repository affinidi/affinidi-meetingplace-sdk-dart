import 'dart:convert';

import 'chat_attachment.dart';

/// Parsed payload for a signed Cierge agent response attachment.
class CiergeSignatureProof {
  const CiergeSignatureProof({
    required this.signature,
    this.messageId,
    this.signerDid,
    this.timestamp,
    this.tokenId,
    this.context,
    this.memory,
    this.model,
  });

  /// DIDComm attachment format emitted by cierge-mpx-connector.
  static const String attachmentFormat = 'cierge/signature';

  final String signature;
  final String? messageId;
  final String? signerDid;
  final String? timestamp;
  final String? tokenId;
  final String? context;
  final String? memory;
  final String? model;

  static CiergeSignatureProof? fromAttachment(ChatAttachment attachment) {
    if (attachment.format != attachmentFormat) return null;
    final raw = _rawPayload(attachment);
    if (raw == null || raw.trim().isEmpty) return null;
    return fromRawJson(raw);
  }

  static CiergeSignatureProof? fromRawJson(String raw) {
    final decoded = _decodeJsonObject(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final signature = decoded['signature'];
    if (signature is! String || signature.isEmpty) return null;
    return CiergeSignatureProof(
      signature: signature,
      messageId: decoded['messageId'] as String?,
      signerDid: decoded['signerDid'] as String?,
      timestamp: decoded['timestamp'] as String?,
      tokenId: decoded['tokenId'] as String?,
      context: decoded['context'] as String?,
      memory: decoded['memory'] as String?,
      model: decoded['model'] as String?,
    );
  }

  static String? _rawPayload(ChatAttachment attachment) {
    final jsonPayload = attachment.data?.json;
    if (jsonPayload != null && jsonPayload.trim().isNotEmpty) {
      return jsonPayload;
    }

    final base64Payload = attachment.data?.base64;
    if (base64Payload == null || base64Payload.trim().isEmpty) return null;
    try {
      return utf8.decode(base64Decode(base64Payload));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _decodeJsonObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
