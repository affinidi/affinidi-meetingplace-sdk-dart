import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';

class MemberJoinedHandler implements ChatEventHandler {
  MemberJoinedHandler({
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required String chatId,
    required String ownDid,
    required Group Function() getGroup,
  }) : _chatRepository = chatRepository,
       _streamManager = streamManager,
       _chatId = chatId,
       _ownDid = ownDid,
       _getGroup = getGroup;

  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final String _chatId;
  final String _ownDid;
  final Group Function() _getGroup;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final senderDid = event.senderDid;
    if (senderDid == null) return;

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

    final chatItem = await _chatRepository.createMessage(
      EventMessage.groupMemberJoined(
        chatId: _chatId,
        groupDid: group.did,
        memberDid: memberDid,
        memberCard: contactCardData,
      ),
    );

    _streamManager.pushData(StreamData(chatItem: chatItem));
  }
}
