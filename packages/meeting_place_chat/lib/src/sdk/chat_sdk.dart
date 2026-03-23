import '../../meeting_place_chat.dart';
import 'chat.dart';

abstract interface class ChatSDK {
  static bool _automaticDownloadEnabled = true;

  /// Enables automatic download of incoming Matrix media attachments.
  static void enableAutomaticDownload() {
    _automaticDownloadEnabled = true;
  }

  /// Disables automatic download of incoming Matrix media attachments.
  static void disableAutomaticDownload() {
    _automaticDownloadEnabled = false;
  }

  /// Returns whether incoming Matrix media attachments are auto-downloaded.
  static bool isAutomaticDownloadEnabled() {
    return _automaticDownloadEnabled;
  }

  Future<List<ChatItem>> get messages;
  Future<ChatStream?> get chatStreamSubscription;

  Future<Chat> startChatSession();
  void endChatSession();

  Future<ChatItem?> getMessageById(String messageId);
  Future<List<Message>> fetchNewMessages();
  Future<Message> downloadAttachment({
    required String messageId,
    required String attachmentId,
  });

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
}
