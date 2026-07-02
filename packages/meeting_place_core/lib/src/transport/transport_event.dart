/// Transport-agnostic representation of a channel event.
class TransportEvent {
  const TransportEvent({
    required this.id,
    required this.type,
    required this.content,
    required this.channelId,
    required this.timestamp,
    this.senderDid,
    this.isFromMe = false,
    this.isReplay = false,
    this.metadata,
  });

  /// Transport-assigned event identifier (e.g. Matrix `\$eventId`).
  final String id;

  /// Event type string (e.g. `m.room.message`, `m.reaction`).
  final String type;

  /// Event payload.
  final Map<String, dynamic> content;

  /// Identifier for the channel this event belongs to (e.g. room ID for
  /// Matrix, DID for DIDComm).
  final String channelId;

  /// Timestamp of the event, as reported by the transport.
  final DateTime timestamp;

  /// DID of the sender, if the transport resolved it.
  final String? senderDid;

  /// Whether this event was sent by the local client.
  final bool isFromMe;

  /// Whether this event came from a history backfill rather than the live
  /// stream.
  final bool isReplay;

  /// Transport-specific metadata not part of the standard event payload.
  /// Transports may populate this with implementation details that higher
  /// layers need without polluting [content].
  final Map<String, dynamic>? metadata;
}
