import 'dart:typed_data';

import '../meeting_place_chat.dart';

abstract interface class ChatSDK {
  Future<List<ChatItem>> get messages;
  Future<ChatStream?> get chatStreamSubscription;

  Future<Chat> startChatSession();
  void endChatSession();

  Future<ChatItem?> getMessageById(String messageId);

  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment>? attachments,
  });

  Future<Uint8List> downloadMedia(ChatAttachment attachment);

  // TODO: add custom message
  Future<void> sendChatActivity();
  Future<void> sendEffect(Effect effect);
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message);
  Future<void> reactOnMessage(Message message, {required String reaction});

  Future<void> approveConnectionRequest(ConciergeMessage message);
  Future<void> rejectConnectionRequest(ConciergeMessage message);

  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message);

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates();
}
