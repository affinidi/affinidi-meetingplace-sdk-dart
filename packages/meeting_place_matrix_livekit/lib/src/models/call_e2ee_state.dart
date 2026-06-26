/// E2EE state for a participant's media stream.
///
/// Transport-layer analog of the LiveKit `E2EEState` enum. Kept in the pure
/// Dart SDK layer so `AudioVideoCallService` can react to encryption state
/// changes without depending on livekit_client.
enum CallE2EEState {
  /// Encryption is established and media is flowing.
  ok,

  /// A new encryption key has been ratcheted.
  keyRatcheted,

  /// Initial state before E2EE negotiation completes.
  newState,

  /// The remote participant's key has not arrived yet.
  missingKey,

  /// An outbound frame could not be encrypted.
  encryptionFailed,

  /// An inbound frame could not be decrypted.
  decryptionFailed,

  /// An internal error occurred in the FrameCryptor.
  internalError,
}
