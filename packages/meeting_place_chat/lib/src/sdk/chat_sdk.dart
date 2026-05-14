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

  /// Creates a local chat message for a credential that was issued to the
  /// other party, so the sender sees an attachment tile immediately.
  Future<void> createChatMessageFromIssuedCredential({
    required List<Attachment> attachments,
  });

  /// Creates a local chat message for a credential request received from the
  /// other party, so the recipient sees an attachment tile immediately.
  Future<void> createChatMessageFromRequestCredential({
    required List<Attachment> attachments,
  });
}
