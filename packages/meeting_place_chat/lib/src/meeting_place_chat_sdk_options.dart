import '../meeting_place_chat.dart';

/// [MeetingPlaceChatSDKOptions] defines configurable options for the
/// [MeetingPlaceChatSDK], controlling behaviors such as presence intervals and
/// activity expiry.
///
/// These options allow fine-tuning of chat performance and reliability.
class MeetingPlaceChatSDKOptions {
  /// Creates a new [MeetingPlaceChatSDKOptions] instance.
  ///
  /// **Parameters:**
  /// - [chatPresenceSendInterval]: Interval for sending
  ///   presence signals (default: `10` seconds).
  /// - [chatActivityExpiry]: Expiry time for
  ///   chat activity signals such as "typing" (default: `3` seconds).
  /// - [deleteMessageWindow]: Maximum age for an original sender to delete
  ///   a message for all participants (default: `2` minutes).
  /// - [requiresAcknowledgement]: List of [ChatProtocol] message types
  ///   that require delivery acknowledgement
  ///  (default: `[ChatProtocol.chatMessage]`).
  /// - [memberJoinedIndicator]: List of [ChatProtocol] message types
  ///   that indicate that new group member opened chat screen the first time.
  MeetingPlaceChatSDKOptions({
    this.chatPresenceSendInterval = const Duration(seconds: 10),
    this.chatPresenceExpiry = const Duration(seconds: 15),
    this.chatActivityExpiry = const Duration(seconds: 3),
    this.deleteMessageWindow = const Duration(minutes: 2),
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

  /// Maximum age of a message that can still be deleted for all
  /// participants by its original sender via `BaseChatSDK.deleteMessage`.
  ///
  /// Local-only deletes (`localOnly: true`) ignore this window.
  /// Set to [Duration.zero] to disable wire deletes entirely.
  ///
  /// Defaults to `2` minutes.
  final Duration deleteMessageWindow;

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
}
