import 'package:meeting_place_chat/meeting_place_chat.dart';

/// Resolves the local [Message] targeted by a relation event (reaction or
/// edit) from its Matrix event id.
///
/// The in-memory [_serverEventIdToMessageId] map only covers messages seen
/// live this session, so it misses history and cross-session messages. Fall
/// back to the persisted `transportId` (the Matrix event id) so relations on
/// older messages still resolve instead of being dropped.
class TargetMessageResolver {
  TargetMessageResolver({
    required ChatRepository chatRepository,
    required String chatId,
    required Map<String, String> serverEventIdToMessageId,
  }) : _chatRepository = chatRepository,
       _chatId = chatId,
       _serverEventIdToMessageId = serverEventIdToMessageId;

  final ChatRepository _chatRepository;
  final String _chatId;
  final Map<String, String> _serverEventIdToMessageId;

  Future<Message?> resolve(String targetEventId) async {
    final mappedId = _serverEventIdToMessageId[targetEventId] ?? targetEventId;
    final mapped = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: mappedId,
    );
    if (mapped is Message) return mapped;

    final items = await _chatRepository.listMessages(_chatId);
    for (final item in items) {
      if (item is Message && item.transportId == targetEventId) return item;
    }
    return null;
  }
}
