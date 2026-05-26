import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import '../repository/chat_history_service.dart';
import 'room_event_handler/contact_details_update_handler.dart';
import 'room_event_handler/group_deletion_handler.dart';
import 'room_event_handler/group_details_update_handler.dart';
import 'room_event_handler/member_deregistered_handler.dart';
import 'room_event_handler/member_joined_handler.dart';
import 'room_event_handler/room_member_handler.dart';
import '../transport/matrix/incoming/incoming_room_event_router.dart';
import '../transport/matrix/incoming/room_event_handler.dart';

/// Routes incoming Matrix room events for a [GroupChatSDK]. Extends the
/// common [IncomingRoomEventRouter] dispatch with handlers for group-specific
/// event types.
class GroupRoomEventRouter extends IncomingRoomEventRouter {
  GroupRoomEventRouter({
    required GroupChatSDK chatSDK,
    required ChatHistoryService chatHistoryService,
  }) : super.withHandlers({
         ...IncomingRoomEventRouter.buildBaseHandlers(chatSDK),
         ..._buildGroupHandlers(
           chatSDK: chatSDK,
           chatHistoryService: chatHistoryService,
         ),
       });

  static Map<String, RoomEventHandler> _buildGroupHandlers({
    required GroupChatSDK chatSDK,
    required ChatHistoryService chatHistoryService,
  }) {
    Group getGroup() => chatSDK.group;
    void setGroup(Group g) => chatSDK.group = g;

    return {
      matrix.EventTypes.RoomMember: RoomMemberHandler(
        joinedHandler: MemberJoinedHandler(
          chatRepository: chatSDK.chatRepository,
          chatHistoryService: chatHistoryService,
          streamManager: chatSDK.chatStream,
          didCache: chatSDK.didCache,
          chatId: chatSDK.chatId,
          ownDid: chatSDK.did,
          getGroup: getGroup,
        ),
        leftHandler: MemberDeregisteredHandler(
          coreSDK: chatSDK.coreSDK,
          chatHistoryService: chatHistoryService,
          streamManager: chatSDK.chatStream,
          didCache: chatSDK.didCache,
          chatId: chatSDK.chatId,
          getGroup: getGroup,
          setGroup: setGroup,
        ),
      ),
      MeetingPlaceProtocol.groupDeletion.value: GroupDeletionHandler(
        coreSDK: chatSDK.coreSDK,
        chatHistoryService: chatHistoryService,
        streamManager: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
      ChatProtocol.chatGroupDetailsUpdate.value: GroupDetailsUpdateHandler(
        coreSDK: chatSDK.coreSDK,
        chatHistoryService: chatHistoryService,
        streamManager: chatSDK.chatStream,
        didCache: chatSDK.didCache,
        chatId: chatSDK.chatId,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
      ChatProtocol.chatContactDetailsUpdate.value: ContactDetailsUpdateHandler(
        chatSDK: chatSDK,
        streamManager: chatSDK.chatStream,
        didCache: chatSDK.didCache,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
    };
  }
}
