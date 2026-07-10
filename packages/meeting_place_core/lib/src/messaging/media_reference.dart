/// Transport-agnostic identifier for previously sent media that can be
/// resolved back to bytes via `MessagingService.downloadMedia`.
///
/// Each transport produces its own subtype: Matrix carries a server-assigned
/// event id; future transports (DIDComm with hosted storage, S3, etc.) will
/// add their own reference shape without breaking the public surface.
abstract class MediaReference {
  const MediaReference();

  /// Transport-assigned identifier used to retrieve the media bytes.
  String get fileId;
}
