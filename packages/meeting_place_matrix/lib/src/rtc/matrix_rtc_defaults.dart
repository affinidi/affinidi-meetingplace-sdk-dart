/// Non-negotiable backend defaults for MPX MatrixRTC calls.
///
/// These are intentional security and UX invariants, not tuneable options.
/// Do not expose them as caller-configurable parameters.
abstract final class MatrixRtcDefaults {
  /// E2EE is always enabled for MPX calls.
  ///
  /// Disabling this would transmit media keys in plaintext over the Matrix
  /// homeserver. There is no product scenario where that is acceptable.
  static const bool e2eeEnabled = true;

  /// Keys are always pre-shared before entering the call.
  ///
  /// Pre-sharing distributes the local encryption key to existing participants
  /// before the group call session is entered, so remote parties can decrypt
  /// the local track from the first frame. Setting this to false causes an
  /// extra round-trip key exchange after connection, resulting in an encrypted
  /// but undecryptable stream until the key arrives.
  static const bool preShareKey = true;

  /// Maximum time to wait for an incoming MatrixRTC membership to surface
  /// after lazily activating a session via `activateIncomingCall`.
  ///
  /// The membership is usually already present in room state when activation
  /// is triggered by a call push; this bounds the wait for the case where the
  /// first sync has not yet delivered it.
  static const Duration incomingCallActivationTimeout = Duration(seconds: 10);
}
