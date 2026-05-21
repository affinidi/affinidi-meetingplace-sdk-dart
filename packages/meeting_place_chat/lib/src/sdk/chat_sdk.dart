import '../../meeting_place_chat.dart';

abstract interface class ChatSDK {
  Future<List<ChatItem>> get messages;
  Future<ChatStream?> get chatStreamSubscription;

  Future<Chat> startChatSession();
  void endChatSession();

  Future<ChatItem?> getMessageById(String messageId);
  Future<List<Message>> fetchNewMessages();

  Future<Message> sendTextMessage(String text, {List<Attachment>? attachments});

  Future<void> sendMessage(PlainTextMessage message, {bool notify = false});
  Future<void> sendProfileHash();
  Future<void> sendChatActivity();
  Future<void> sendChatPresence();
  Future<void> sendEffect(Effect effect);
  Future<void> sendChatDeliveredMessage(PlainTextMessage message);
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message);
  Future<void> reactOnMessage(Message message, {required String reaction});

  Future<void> approveConnectionRequest(ConciergeMessage message);
  Future<void> rejectConnectionRequest(ConciergeMessage message);

  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message);

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates();

  /// Creates a local chat message with attachments.
  ///
  /// [senderDid] must be the DID of the party who sent the credential —
  /// pass `Channel.permanentChannelDid` for an outgoing exchange, or
  /// `Channel.otherPartyPermanentChannelDid` for an incoming one.
  Future<void> createAttachmentMessage({
    required List<Attachment> attachments,
    required String senderDid,
  });
}
