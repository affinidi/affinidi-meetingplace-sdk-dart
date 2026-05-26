import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import 'event_handler/contact_details_update_handler.dart';
import 'event_handler/group_deletion_handler.dart';
import 'event_handler/group_details_update_handler.dart';
import 'event_handler/member_deregistered_handler.dart';
import 'event_handler/member_joined_handler.dart';
import '../../transport/matrix/incoming/incoming_room_event_router.dart';

/// Routes incoming Matrix room events for a [GroupChatSDK]. Extends the
/// common [IncomingRoomEventRouter] dispatch with transport-neutral
/// [ChatEventHandler]s for group-specific event types.
class GroupRoomEventRouter extends IncomingRoomEventRouter {
  GroupRoomEventRouter({required GroupChatSDK chatSDK})
    : super.withHandlers(
        didCache: chatSDK.didCache,
        matrixHandlers: IncomingRoomEventRouter.buildBaseHandlers(chatSDK),
        chatHandlers: _buildGroupHandlers(chatSDK: chatSDK),
      );

  static Map<String, ChatEventHandler> _buildGroupHandlers({
    required GroupChatSDK chatSDK,
  }) {
    Group getGroup() => chatSDK.group;
    void setGroup(Group g) => chatSDK.group = g;

    return {
      ChatEventTypes.memberJoined: MemberJoinedHandler(
        chatRepository: chatSDK.chatRepository,
        streamManager: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        ownDid: chatSDK.did,
        getGroup: getGroup,
      ),
      ChatEventTypes.memberLeft: MemberDeregisteredHandler(
        coreSDK: chatSDK.coreSDK,
        chatRepository: chatSDK.chatRepository,
        streamManager: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
      ChatEventTypes.groupDeletion: GroupDeletionHandler(
        coreSDK: chatSDK.coreSDK,
        chatRepository: chatSDK.chatRepository,
        streamManager: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
      ChatEventTypes.groupDetailsUpdate: GroupDetailsUpdateHandler(
        coreSDK: chatSDK.coreSDK,
        chatRepository: chatSDK.chatRepository,
        streamManager: chatSDK.chatStream,
        registerMemberDids: chatSDK.didCache.registerAll,
        chatId: chatSDK.chatId,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
      ChatEventTypes.contactDetailsUpdate: ContactDetailsUpdateHandler(
        chatSDK: chatSDK,
        streamManager: chatSDK.chatStream,
        getGroup: getGroup,
        setGroup: setGroup,
      ),
    };
  }
}
