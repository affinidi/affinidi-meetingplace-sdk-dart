import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';

class MemberJoinedHandler implements ChatEventHandler {
  MemberJoinedHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required String chatId,
    required String ownDid,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _streamManager = streamManager,
       _chatId = chatId,
       _ownDid = ownDid,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final String _chatId;
  final String _ownDid;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    // targetDid is resolved from the m.room.member stateKey via in-memory
    // group members, which is more reliable than senderDid (requires persisted
    // group lookup that may fail if the member isn't yet in the repository).
    final memberDid = event.targetDid ?? event.senderDid;
    if (memberDid == null) return;

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
              eventMessage.data['memberDid'] == memberDid,
        );

    if (matchingMessage == null) return;

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

    final updatedGroup = await _coreSDK.getGroupById(group.id);
    if (updatedGroup != null) {
      _setGroup(updatedGroup);
    }

    _streamManager.pushData(StreamData(chatItem: chatItem));
  }
}
