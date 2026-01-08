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
  ChatSDKOptions({
    this.chatPresenceSendInterval = const Duration(seconds: 10),
    this.chatPresenceExpiry = const Duration(seconds: 15),
    this.chatActivityExpiry = const Duration(seconds: 3),
    this.requiresAcknowledgement = const [ChatProtocol.chatMessage],
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
    this.sendProfileHashEnabled = true,
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

  /// Whether to send profile hash messages when starting chat session.
  final bool sendProfileHashEnabled;
}
