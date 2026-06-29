/// Transport-agnostic identifier for previously sent media that can be
/// resolved back to bytes via `MessagingService.downloadMedia`.
///
/// Each transport produces its own subtype: Matrix carries a server-assigned
/// event id; future transports (DIDComm with hosted storage, S3, etc.) will
/// add their own reference shape without breaking the public surface.
sealed class MediaReference {
  const MediaReference();

  /// Transport-assigned identifier used to retrieve the media bytes.
  String get fileId;
}

/// Reference to a media payload posted as a Matrix `m.room.message` event.
final class MatrixEventMediaReference extends MediaReference {
  const MatrixEventMediaReference(this.eventId);

  /// Server-assigned event id returned by `MessagingService.sendMediaMessage`
  /// for Matrix channels.
  final String eventId;

  @override
  String get fileId => eventId;
}
