import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../repository/chat_history_service.dart';
import '../../../transport/matrix/matrix_user_id_cache.dart';
import '../../../transport/matrix/incoming/room_event_handler.dart';

class MemberJoinedHandler implements RoomEventHandler {
  MemberJoinedHandler({
    required ChatRepository chatRepository,
    required ChatHistoryService chatHistoryService,
    required ChatStream streamManager,
    required MatrixUserIdCache didCache,
    required String chatId,
    required String ownDid,
    required Group Function() getGroup,
  }) : _chatRepository = chatRepository,
       _chatHistoryService = chatHistoryService,
       _streamManager = streamManager,
       _didCache = didCache,
       _chatId = chatId,
       _ownDid = ownDid,
       _getGroup = getGroup;

  final ChatRepository _chatRepository;
  final ChatHistoryService _chatHistoryService;
  final ChatStream _streamManager;
  final MatrixUserIdCache _didCache;
  final String _chatId;
  final String _ownDid;
  final Group Function() _getGroup;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = _didCache.resolve(event.userId);
    if (senderDid == null) return;
    _didCache.register(senderDid);

    final group = _getGroup();
    final isGroupOwner = group.ownerDid == _ownDid;
    if (!isGroupOwner) return;

    final allMessages = await _chatRepository.listMessages(_chatId);
    final matchingMessage = allMessages
        .whereType<EventMessage>()
        .firstWhereOrNull(
          (eventMessage) =>
              eventMessage.status != ChatItemStatus.confirmed &&
              eventMessage.eventType ==
                  EventMessageType.awaitingGroupMemberToJoin &&
              eventMessage.data['memberDid'] == senderDid,
        );

    if (matchingMessage == null) return;

    final memberDid = matchingMessage.data['memberDid'];
    if (memberDid is! String) {
      throw StateError(
        'Expected awaitingGroupMemberToJoin event to include memberDid.',
      );
    }

    final contactCardData = matchingMessage.data['contactCard'];
    if (contactCardData is! Map<String, dynamic>) {
      throw StateError(
        'Expected awaitingGroupMemberToJoin event to include contactCard data.',
      );
    }

    matchingMessage.status = ChatItemStatus.confirmed;
    await _chatRepository.updateMesssage(matchingMessage);
    _streamManager.pushData(StreamData(chatItem: matchingMessage));

    final chatItem = await _chatHistoryService
        .createGroupMemberJoinedGroupEventMessage(
          chatId: _chatId,
          groupDid: group.did,
          memberDid: memberDid,
          memberCard: ContactCard.fromJson(contactCardData),
        );

    _streamManager.pushData(StreamData(chatItem: chatItem));
  }
}
