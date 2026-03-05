import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';

class ChatReactionHandler {
  ChatReactionHandler({
    required ChatRepository chatRepository,
    required ChatStream streamManager,
  }) : _chatRepository = chatRepository,
       _streamManager = streamManager;

  final ChatRepository _chatRepository;
  final ChatStream _streamManager;

  Future<void> handle({
    required MediatorMessage message,
    required String chatId,
  }) async {
    final chatReactionMessage = ChatReaction.fromPlainTextMessage(
      message.plainTextMessage,
    );

    final repositoryMessage = await _chatRepository.getMessage(
      chatId: chatId,
      messageId: chatReactionMessage.body.messageId,
    );

    if (repositoryMessage is! Message) {
      throw Exception('Reactions only supported for chat messages');
    }

    repositoryMessage.reactions = chatReactionMessage.body.reactions;
    await _chatRepository.updateMesssage(repositoryMessage);

    _streamManager.pushData(
      StreamData(
        plainTextMessage: message.plainTextMessage,
        chatItem: repositoryMessage,
      ),
    );
  }
}
