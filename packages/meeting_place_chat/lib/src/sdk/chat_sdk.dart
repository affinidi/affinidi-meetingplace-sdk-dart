import '../../meeting_place_chat.dart';
import 'chat.dart';

abstract interface class ChatSDK {
  Future<List<ChatItem>> get messages;
  Future<ChatStream?> get chatStreamSubscription;
  ChatRepository get chatRepository;

  Future<Chat> startChatSession();
  void endChatSession();

  Future<ChatItem?> getMessageById(String messageId);
  Future<List<Message>> fetchNewMessages();

  Future<Message> sendTextMessage(String text, {List<Attachment>? attachments});

  Future<void> sendMessage(PlainTextMessage message, {bool notify = false});
  Future<void> sendProfileHash();
  Future<void> sendChatActivity();
  Future<void> sendChatPresence({bool notify = false});
  Future<void> sendEffect(Effect effect);
  Future<void> sendChatDeliveredMessage(PlainTextMessage message);
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message);
  Future<void> reactOnMessage(Message message, {required String reaction});

  Future<void> approveConnectionRequest(ConciergeMessage message);
  Future<void> rejectConnectionRequest(ConciergeMessage message);

  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message);

  // Temporary solution
  Future<void> createChatMessageFromRequestCredential({
    required List<Attachment> attachments,
  });

  // Temporary solution
  Future<void> createChatMessageFromIssuedCredential({
    required List<Attachment> attachments,
  });
}
