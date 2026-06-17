/// Capability vocabulary for Meeting Place chat.
///
/// [ChatFeature] enumerates the features that can vary between chats.
/// [TransportCapabilities] is the value type that holds a set of them.
///
/// The capability set for each kind of chat is declared by the chat SDK that
/// owns and enforces those features, and exposed through its `capabilities`
/// getter: `IndividualDidcommChatSDK`, `IndividualMatrixChatSDK`, and
/// `GroupMatrixChatSDK`.
library;

/// A discrete feature that a chat may or may not support.
///
/// Query via [TransportCapabilities.supports] before exposing UI actions
/// that depend on a specific capability.
enum ChatFeature {
  /// Plain text message sending and receiving.
  textMessaging,

  /// File and image attachments. Delivered as hosted media on transports with
  /// a media server (Matrix) and inline within the message on transports
  /// without one (DIDComm).
  mediaAttachments,

  /// Voice-note recording and playback as a hosted media attachment.
  voiceMessages,

  /// Emoji/reaction toggling on messages.
  reactions,

  /// Live typing indicator sent to other participants.
  typingIndicators,

  /// Online-presence broadcasts (e.g. "last seen").
  presence,

  /// Read/delivery receipt propagation.
  deliveryReceipts,

  /// In-place editing of already-sent text messages.
  messageEdit,

  /// Deletion of a sent message: redacted for all participants, or hidden
  /// locally for the current user only. A transport either supports message
  /// deletion (both modes) or none of it.
  messageDelete,

  /// Visual effect broadcasts (e.g. confetti).
  effects,

  /// Contact-card proposal and acceptance flow.
  contactDetailsUpdate,
}

/// The set of [ChatFeature]s supported by a kind of chat.
///
/// Query [supports] before offering any UI or action that depends on a given
/// feature:
///
/// ```dart
/// if (chatSDK.capabilities.supports(ChatFeature.messageEdit)) {
///   // show edit option
/// }
/// ```
///
/// Each concrete chat SDK declares its own set and returns it from
/// `capabilities`.
class TransportCapabilities {
  const TransportCapabilities(this.features);

  /// The features supported by this kind of chat.
  final Set<ChatFeature> features;

  /// Returns `true` when this kind of chat supports [feature].
  bool supports(ChatFeature feature) => features.contains(feature);
}
