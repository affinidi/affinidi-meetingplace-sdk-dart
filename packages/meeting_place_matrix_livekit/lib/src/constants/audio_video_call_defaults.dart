/// Non-negotiable LiveKit E2EE defaults for MPX calls.
///
/// These are intentional security invariants, not tuneable options.
/// Do not expose them as caller-configurable parameters.
abstract final class AudioVideoCallDefaults {
  /// Per-participant E2EE keys are always used.
  ///
  /// A shared key (`sharedKey: true`) uses a single room-wide encryption key
  /// for all participants. Per-participant keys (`sharedKey: false`) mean each
  /// participant generates their own key and distributes it individually. This
  /// model is required for key rotation on participant departure: when someone
  /// leaves, only their key needs to be rotated rather than re-keying the
  /// entire room.
  // static const bool sharedKeyEncryption = false;

  // TODO (Earl): restore per-participant keys (`false`) once the matrix
  // to-device key exchange reliably delivers the publisher key on join. The
  // shared key below is a temporary measure to keep calls functional.
  static const bool sharedKeyEncryption = true;
}
