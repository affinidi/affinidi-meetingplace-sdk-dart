import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';

class ChatGroupAliasProfileRequestHandler {
  ChatGroupAliasProfileRequestHandler({
    required ChatRepository chatRepository,
    required ChatStream streamManager,
  }) : _chatRepository = chatRepository,
       _streamManager = streamManager;

  final ChatRepository _chatRepository;
  final ChatStream _streamManager;

  Future<void> handle({
    required PlainTextMessage message,
    required String chatId,
  }) async {
    // TODO: add concierge message handler
    final existingMessages = await _chatRepository.listMessages(chatId);
    final targets = existingMessages.where(
      (m) =>
          m is ConciergeMessage &&
          m.conciergeType == ConciergeMessageType.permissionToUpdateProfile &&
          m.status == ChatItemStatus.userInput,
    );

    await Future.wait(
      targets.map((t) async {
        t.status = ChatItemStatus.confirmed;
        await _chatRepository.updateMesssage(t);
        _streamManager.pushData(StreamData(chatItem: t));
      }),
    );

    final conciergeMessage = ConciergeMessage(
      chatId: chatId,
      messageId: const Uuid().v4(),
      senderDid: message.from!,
      isFromMe: false,
      dateCreated: message.createdTime ?? DateTime.now().toUtc(),
      status: ChatItemStatus.userInput,
      conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      data: {
        'profileHash': message.body?['profile_hash'],
        'replyTo': message.from!,
      },
    );

    await _chatRepository.createMessage(conciergeMessage);
    _streamManager.pushData(
      StreamData(plainTextMessage: message, chatItem: conciergeMessage),
    );
  }
}
