import '../../meeting_place_chat.dart';

/// [ChatSDKOptions] defines configurable options for the [MeetingPlaceChatSDK],
/// controlling behaviors such as presence intervals, activity expiry,
/// and acknowledgement rules.
///
/// These options allow fine-tuning of chat performance and reliability.
class ChatSDKOptions {
  /// Creates a new [ChatSDKOptions] instance.
  ///
  /// **Parameters:**
  /// - [chatPresenceSendInterval]: Interval in seconds for sending
  ///   presence signals (default: `10` seconds).
  /// - [chatActivityExpiresInSeconds]: Expiry time in seconds for
  ///   chat activity signals such as "typing" (default: `3` seconds).
  /// - [requiresAcknowledgement]: List of [ChatProtocol] message types
  ///   that require delivery acknowledgement
  ///  (default: `[ChatProtocol.chatMessage]`).
  /// - [memberJoinedIndicator]: List of [ChatProtocol] message types
  ///   that indicate that new group member opened chat screen the first time.
  /// - [trackMatrixReceipts]: Whether to track message delivery via
  ///   Matrix read receipts (default: `true`).
  /// - [honoredReceiptTypes]: Which Matrix receipt types to honor for
  ///   delivery tracking (default: `{'m.read', 'm.read.private'}`).
  /// - [autoSendMatrixReceipts]: Whether to automatically send Matrix
  ///   read receipts when receiving messages (default: `true`).
  ChatSDKOptions({
    this.chatPresenceSendInterval = const Duration(seconds: 10),
    this.chatPresenceExpiry = const Duration(seconds: 15),
    this.chatActivityExpiry = const Duration(seconds: 3),
    this.requiresAcknowledgement = const [ChatProtocol.chatMessage],
    this.onlyHandleMentionedMatrixMessages = false,
    this.trackMatrixReceipts = true,
    this.autoSendMatrixReceipts = true,
    this.honoredReceiptTypes = const {'m.read', 'm.read.private'},
    this.memberJoinedIndicator = const [
      ChatProtocol.chatPresence,
      ChatProtocol.chatMessage,
      ChatProtocol.chatActivity,
      ChatProtocol.chatAliasProfileHash,
      ChatProtocol.chatAttachmentsVerifiablePresentation,
      ChatProtocol.chatDelivered,
      ChatProtocol.chatEffect,
      ChatProtocol.chatMessage,
      ChatProtocol.chatReaction,
    ],
  });

  /// The list of message types that require delivery acknowledgement.
  ///
  /// Defaults to `[ChatProtocol.chatMessage]`.
  final List<ChatProtocol> requiresAcknowledgement;

  /// The interval (in seconds) at which presence signals
  /// (e.g., "online") are sent to the other party.
  ///
  /// Defaults to `10` seconds.
  final Duration chatPresenceSendInterval;

  /// The interval (in seconds) at which presence signals
  /// (e.g., "online") are sent to the other party.
  ///
  /// Defaults to `10` seconds.
  final Duration chatPresenceExpiry;

  /// The expiry duration (in seconds) for activity messages
  /// such as typing indicators.
  ///
  /// Defaults to `3` seconds.
  final Duration chatActivityExpiry;

  /// When `true`, incoming Matrix room messages are only processed and surfaced
  /// to the consumer if the local user's Matrix ID appears in the event's
  /// `m.mentions.user_ids` list.
  ///
  /// Defaults to `false` (all messages are delivered regardless of mentions).
  final bool onlyHandleMentionedMatrixMessages;

  /// List of ChatProtocol message types used to determine whether a member
  /// has opened the chat screen for the first time after joining the group.
  ///
  /// Defaults to message types:
  /// - ChatProtocol.chatMessage,
  /// - ChatProtocol.chatActivity,
  /// - ChatProtocol.chatAliasProfileHash,
  /// - ChatProtocol.chatAttachmentsVerifiablePresentation,
  /// - ChatProtocol.chatDelivered,
  /// - ChatProtocol.chatEffect,
  /// - ChatProtocol.chatMessage,
  /// - ChatProtocol.chatReaction,
  final List<ChatProtocol> memberJoinedIndicator;

  /// Whether to track message delivery via Matrix read receipts.
  ///
  /// When `true`, messages sent in group chats will update to 'delivered'
  /// status when other members send `m.read` or `m.read.private` receipts.
  ///
  /// Defaults to `true`.
  final bool trackMatrixReceipts;

  /// Which Matrix receipt types to honor for delivery tracking.
  ///
  /// Receipts of these types will trigger message status updates to 'delivered'.
  /// Both `m.read` (public) and `m.read.private` indicate the message was received.
  ///
  /// Defaults to `{'m.read', 'm.read.private'}`.
  final Set<String> honoredReceiptTypes;

  /// Whether to automatically send Matrix read receipts when receiving messages.
  ///
  /// When `true`, the SDK will automatically send `m.read` receipts for incoming
  /// Matrix messages, which triggers delivery status updates for the sender.
  ///
  /// Defaults to `true`.
  final bool autoSendMatrixReceipts;
}
