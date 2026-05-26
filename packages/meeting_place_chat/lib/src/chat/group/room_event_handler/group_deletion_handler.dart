import 'package:meeting_place_core/meeting_place_core.dart';

import '../chat_history_service.dart';
import '../../../event/chat_event_conversion.dart';
import '../../../event/chat_stream.dart';
import '../../../event/stream_data.dart';
import '../../../transport/matrix/incoming/room_event_handler.dart';

class GroupDeletionHandler implements RoomEventHandler {
  GroupDeletionHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatHistoryService chatHistoryService,
    required ChatStream streamManager,
    required String chatId,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _coreSDK = coreSDK,
       _chatHistoryService = chatHistoryService,
       _streamManager = streamManager,
       _chatId = chatId,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatHistoryService _chatHistoryService;
  final ChatStream _streamManager;
  final String _chatId;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final group = _getGroup();

    if (!group.isDeleted) {
      group.markAsDeleted();
      await _coreSDK.updateGroup(group);
      _setGroup(group);

      final chatItem = await _chatHistoryService.createGroupDeletedEventMessage(
        chatId: _chatId,
        groupDid: group.did,
      );

      _streamManager.pushData(StreamData(chatItem: chatItem));
    }

    _streamManager.pushData(StreamData(event: event.toChatEvent()));
  }
}
