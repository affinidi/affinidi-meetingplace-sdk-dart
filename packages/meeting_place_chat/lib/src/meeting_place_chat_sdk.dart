import 'package:meeting_place_core/meeting_place_core.dart';

import '../meeting_place_chat.dart';

/// Public interface for a single chat session in the Meeting Place SDK.
///
/// A [MeetingPlaceChatSDK] is always scoped to one chat — either an individual
/// chat with one peer or a group chat — and is obtained via
/// [MeetingPlaceChatSDK.initialiseFromChannel]. The concrete implementation
/// ([GroupMatrixChatSDK], [IndividualMatrixChatSDK], or
/// [IndividualDidcommChatSDK]) is selected from the underlying channel.
///
/// Responsibilities:
/// - Lifecycle: start/end the chat session and expose the live event stream.
/// - Messaging: send and edit text messages, reactions, effects, and activity
///   (typing) signals.
/// - Membership: approve/reject pending connection requests (group only).
/// - Contact details: propose, accept, or reject contact-card updates.
abstract interface class MeetingPlaceChatSDK {
  /// Builds the right [MeetingPlaceChatSDK] implementation for [channel].
  ///
  /// Groups always use Matrix. Individual channels dispatch on
  /// [Channel.transport] between [IndividualMatrixChatSDK] and
  /// [IndividualDidcommChatSDK].
  static Future<MeetingPlaceChatSDK> initialiseFromChannel(
    Channel channel, {
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required MeetingPlaceChatSDKOptions options,
    ContactCard? card,
    MeetingPlaceChatSDKLogger? logger,
  }) async {
    if (channel.type == ChannelType.group) {
      final group =
          await coreSDK.getGroupByOfferLink(channel.offerLink) ??
          (throw Exception('Group not found'));

      return GroupMatrixChatSDK(
        coreSDK: coreSDK,
        group: group,
        did: channel.permanentChannelDid!,
        otherPartyDid: channel.otherPartyPermanentChannelDid!,
        mediatorDid: channel.mediatorDid,
        chatRepository: chatRepository,
        options: options,
        card: card,
        logger: logger,
      );
    }

    return switch (channel.transport) {
      ChannelTransport.matrix => IndividualMatrixChatSDK(
        coreSDK: coreSDK,
        did: channel.permanentChannelDid!,
        otherPartyDid: channel.otherPartyPermanentChannelDid!,
        mediatorDid: channel.mediatorDid,
        chatRepository: chatRepository,
        options: options,
        card: card,
        logger: logger,
      ),
      ChannelTransport.didcomm => IndividualDidcommChatSDK(
        coreSDK: coreSDK,
        did: channel.permanentChannelDid!,
        otherPartyDid: channel.otherPartyPermanentChannelDid!,
        mediatorDid: channel.mediatorDid,
        chatRepository: chatRepository,
        options: options,
        card: card,
        logger: logger,
      ),
    };
  }

  /// All messages for this chat, ordered as the underlying transport returns
  /// them. Matrix replays the room timeline; DIDComm returns the locally
  /// persisted set.
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

  /// Sends a plain text message with optional [attachments]. Returns the
  /// persisted [Message] once it has been dispatched (status reflects whether
  /// the send succeeded).
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment>? attachments,
  });

  /// Edits a previously sent text [message] to [newText]. Only the original
  /// sender can edit a message; the message must have been delivered.
  Future<void> editTextMessage(Message message, String newText);

  /// Sends a typing / activity indicator for this chat. The signal expires
  /// after the configured `chatActivityExpiry`.
  Future<void> sendChatActivity();

  /// Broadcasts a visual chat [effect] (e.g. a confetti burst) to the other
  /// participants.
  Future<void> sendEffect(Effect effect);

  /// Accepts the contact-details update prompted by [message] and broadcasts
  /// the local contact card to the other participants.
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message);

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

  /// Rejects the contact-details update prompted by [message] without
  /// broadcasting any card change; marks the concierge message as confirmed.
  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message);

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates();

  /// Transport-neutral escape hatch for sending an arbitrary event with the
  /// given [type] and [payload] to the other participants. The concrete
  /// transport (Matrix room event or DIDComm plain text message) is chosen by
  /// the implementation; the SDK does not persist a [ChatItem] for the sender
  /// and does not push to the chat stream.
  Future<void> sendCustomEvent({
    required String type,
    required Map<String, dynamic> payload,
  });
}
