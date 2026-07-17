import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../meeting_place_chat.dart';

/// Public interface for a single chat session in the Meeting Place SDK.
///
/// A [MeetingPlaceChatSDK] is always scoped to one chat. The concrete
/// implementation is selected from the underlying channel.
///
/// Responsibilities:
/// - Lifecycle: start/end the chat session and expose the live event stream.
/// - Messaging: send and edit text messages, reactions, effects, and activity
///   (typing) signals.
/// - Membership: approve/reject pending connection requests (group only).
/// - Contact details: propose, accept, or reject contact-card updates.
abstract interface class MeetingPlaceChatSDK {
  /// Creates a [MeetingPlaceChatSDK] instance based on [Channel].
  static MeetingPlaceChatSDK initialiseChatFromChannel(
    Channel channel, {
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required MeetingPlaceChatSDKOptions options,
    ContactCard? card,
    MeetingPlaceChatSDKLogger? logger,
  }) {
    if (channel.type == ChannelType.group) {
      throw ArgumentError(
        'Group channels are not supported by meeting_place_chat. '
        'Use meeting_place_matrix instead.',
      );
    }

    if (channel.transport != ChannelTransport.didcomm) {
      throw ArgumentError(
        'Transport ${channel.transport} is not supported by meeting_place_chat.'
        'Use meeting_place_matrix for Matrix channels.',
      );
    }

    return IndividualDidcommChatSDK(
      coreSDK: coreSDK,
      did: channel.permanentChannelDid!,
      otherPartyDid: channel.otherPartyPermanentChannelDid!,
      mediatorDid: channel.mediatorDid,
      chatRepository: chatRepository,
      options: options,
      card: card,
      logger: logger,
    );
  }

  ///
  /// Each concrete chat SDK declares its own set, so this reflects both the
  /// transport and the chat type (individual vs group). Query before exposing
  /// UI/actions that depend on a specific capability:
  ///
  /// ```dart
  /// if (chatSDK.capabilities.supports(ChatFeature.messageEdit)) {
  ///   // show edit option
  /// }
  /// ```
  TransportCapabilities get capabilities;

  /// All messages for this chat, ordered as the underlying transport returns
  /// them.
  Future<List<ChatItem>> get messages;

  /// Stream of live chat events for this session, or `null` if
  /// [startChatSession] has not been called yet. Resolves once the transport
  /// subscription is ready so callers don't miss the first events.
  Future<ChatStream?> get chatStreamSubscription;

  /// Starts the chat session: subscribes to the transport, replays history,
  /// and returns the initial [Chat] snapshot.
  Future<Chat> startChatSession();

  /// Ends the chat session, cancelling the transport subscription and
  /// disposing the live [ChatStream].
  Future<void> endChatSession();

  /// Retrieves a single persisted message by its local [messageId], or `null`
  /// if no such message exists in this chat.
  Future<ChatItem?> getMessageById(String messageId);

  /// Sends a plain text message with optional [attachments].
  ///
  /// Text and media travel together: each attachment is sent as a single
  /// transport event carrying [text] as its caption. When multiple
  /// attachments are supplied, only the first event carries [text]; the
  /// rest are sent without a caption. Returns the single persisted
  /// [Message] carrying all attachments.
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment> attachments = const [],
  });

  /// Downloads and decrypts the media bytes referenced by
  /// [attachment]. The wire-level reference ([ChatAttachment.transportId])
  /// is resolved internally so app code never sees encryption keys or
  /// transport URIs.
  Future<Uint8List> downloadMedia(ChatAttachment attachment);

  /// Edits a previously sent text [message] to [newText]. Only the original
  /// sender can edit a message; the message must have been delivered.
  Future<void> editTextMessage(Message message, String newText);

  /// Deletes [message]. Only the original sender may delete a message. When
  /// [localOnly] is `true`, hides the message for the local user without
  /// sending any wire traffic, with no time limit. When `false` (default),
  /// broadcasts a redaction so all participants drop the message; allowed
  /// only within `deleteMessageWindow`.
  Future<void> deleteMessage(Message message, {bool localOnly = false});

  /// Updates a persisted [message] in the local repository and re-emits it
  /// to the chat stream so the UI reflects the change immediately.
  Future<void> updateMessage(Message message);

  /// Maximum age at which the original sender can still delete one of their
  /// own messages for everyone. Mirrors
  /// [MeetingPlaceChatSDKOptions.deleteMessageWindow].
  Duration get deleteMessageWindow;

  /// Sends a typing / activity indicator for this chat. The signal expires
  /// after the configured `chatActivityExpiry`.
  Future<void> sendChatActivity();

  /// Broadcasts a visual chat [effect] (e.g. a confetti burst) to the other
  /// participants.
  Future<void> sendEffect(Effect effect);

  /// Accepts the contact-details update prompted by [message] and broadcasts
  /// the signing identity's contact card to the other participants.
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message);

  /// Refreshes the local contact card snapshot for this chat session and lets
  /// the SDK decide whether that change should produce a profile-update flow.
  Future<void> refreshCurrentContactCard(ContactCard? card);

  /// Toggles [reaction] on [message]. Adds the reaction if absent and removes
  /// it if already present.
  Future<void> reactOnMessage(Message message, {required String reaction});

  /// Approves a pending connection request represented by [message]. Group
  /// chats only — implementations for individual chats throw
  /// [UnimplementedError].
  Future<void> approveConnectionRequest(ConciergeMessage message);

  /// Rejects a pending connection request represented by [message]. Group
  /// chats only — implementations for individual chats throw
  /// [UnimplementedError].
  Future<void> rejectConnectionRequest(ConciergeMessage message);

  /// Removes [memberDid] from the group. Group chats only — implementations
  /// for individual chats throw [UnimplementedError]. Caller must be the
  /// group owner.
  Future<void> removeMember(String memberDid);

  /// Rejects the contact-details update prompted by [message] without
  /// broadcasting any card change; marks the concierge message as confirmed.
  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message);

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates();

  /// Transport-neutral escape hatch for sending an arbitrary event with the
  /// given [type] and [payload] to the other participants. The concrete
  /// transport is chosen by the implementation; the SDK does not persist a
  /// [ChatItem] for the sender and does not push to the chat stream.
  Future<void> sendCustomEvent({
    required String type,
    required Map<String, dynamic> payload,
  });

  /// Creates a local chat message with attachments.
  ///
  /// [senderDid] must be the DID of the party who sent the credential —
  /// pass [Channel.permanentChannelDid] for an outgoing exchange, or
  /// [Channel.otherPartyPermanentChannelDid] for an incoming one.
  Future<void> createAttachmentMessage({
    required List<ChatAttachment> attachments,
    required String senderDid,
  });
}
