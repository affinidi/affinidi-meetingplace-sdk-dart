import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';

class GroupDeletionHandler implements ChatEventHandler {
  GroupDeletionHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required String chatId,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _streamManager = streamManager,
       _chatId = chatId,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final String _chatId;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final group = _getGroup();
    if (group.isDeleted) return;

    group.markAsDeleted();
    await _coreSDK.updateGroup(group);
    _setGroup(group);

    final chatItem = await _chatRepository.createMessage(
      EventMessage.groupDeleted(chatId: _chatId, groupDid: group.did),
    );

    _streamManager.pushData(
      StreamData(
        event: ChatGroupDeletedEvent(groupDid: group.did),
        chatItem: chatItem,
      ),
    );
  }
}
