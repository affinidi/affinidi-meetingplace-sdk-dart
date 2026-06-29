/// Transport-agnostic representation of a channel event.
///
/// Replaces [MatrixRoomEvent] in the [MessagingService] dispatch layer so that
/// the service has no dependency on any matrix-specific type. Implementations
/// map their native event format to [TransportEvent] before emitting.
class TransportEvent {
  const TransportEvent({
    required this.id,
    required this.type,
    required this.content,
    required this.channelId,
    required this.timestamp,
    this.senderDid,
    this.senderId,
    this.stateKey,
    this.isFromMe = false,
    this.isReplay = false,
  }) : assert(
         senderDid != null || senderId != null,
         'Either senderDid or senderId must be provided',
       );

  /// Transport-assigned event identifier (e.g. Matrix `\$eventId`).
  final String id;

  /// Event type string (e.g. `m.room.message`, `m.reaction`).
  final String type;

  /// Event payload.
  final Map<String, dynamic> content;

  /// Identifier for the channel this event belongs to (e.g. room ID for
  /// Matrix, DID for DIDComm).
  final String channelId;

  final DateTime timestamp;

  /// DID of the sender, if the transport resolved it. Null when only the
  /// transport-native user id ([senderId]) is known.
  final String? senderDid;

  /// Transport-native sender identifier (e.g. `@user:server` for Matrix,
  /// a DID for DIDComm). Always set; used as a fallback when [senderDid]
  /// cannot be resolved.
  final String? senderId;

  /// Transport state key (Matrix state events only). Null for all other
  /// event types and for non-Matrix transports.
  final String? stateKey;

  /// Whether this event was sent by the local client.
  final bool isFromMe;

  /// Whether this event came from a history backfill rather than the live
  /// stream.
  final bool isReplay;
}
