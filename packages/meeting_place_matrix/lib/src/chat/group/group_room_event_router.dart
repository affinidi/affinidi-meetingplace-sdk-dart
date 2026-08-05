import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../matrix_room_event.dart';
import '../../matrix_user_id_binding.dart';
import '../../transport/matrix/incoming/incoming_room_event_router.dart';
import 'event_handler/contact_details_update_handler.dart';
import 'event_handler/group_deletion_handler.dart';
import 'event_handler/group_details_update_handler.dart';
import 'event_handler/member_deregistered_handler.dart';
import 'event_handler/member_joined_handler.dart';
import 'group_matrix_chat_sdk.dart';

/// Routes incoming Matrix room events for a [GroupMatrixChatSDK]. Extends the
/// common [IncomingRoomEventRouter] dispatch with transport-neutral
/// [ChatEventHandler]s for group-specific event types.
class GroupRoomEventRouter extends IncomingRoomEventRouter {
  GroupRoomEventRouter({required GroupMatrixChatSDK chatSDK})
    : _chatSDK = chatSDK,
      super.withHandlers(
        matrixHandlers: IncomingRoomEventRouter.buildBaseHandlers(chatSDK),
        chatHandlers: _buildGroupHandlers(chatSDK: chatSDK),
      );

  final GroupMatrixChatSDK _chatSDK;

  /// Resolves the affected user's DID for `m.room.member` events by reverse
  /// lookup against the group's known members. Falls back to the persisted
  /// group when the in-memory snapshot doesn't contain a match, since it may
  /// be stale relative to the joining member. Returns `null` for other event
  /// types or when the state key doesn't match any member in either source.
  @override
  Future<String?> resolveTargetDid(MatrixRoomEvent event) async {
    if (event.type != matrix.EventTypes.RoomMember) return null;
    final stateKey = event.stateKey;
    if (stateKey == null) return null;
    final serverName = stateKey.split(':').last;
    for (final m in _chatSDK.group.members) {
      if (deriveMatrixUserId(m.did, serverName) == stateKey) return m.did;
    }

    final persistedGroup = await _chatSDK.coreSDK.getGroupById(
      _chatSDK.group.id,
    );
    if (persistedGroup == null) return null;
    for (final m in persistedGroup.members) {
      if (deriveMatrixUserId(m.did, serverName) == stateKey) return m.did;
    }
    return null;
  }

  static Map<String, ChatEventHandler> _buildGroupHandlers({
    required GroupMatrixChatSDK chatSDK,
  }) {
    Group getGroup() => chatSDK.group;
    void setGroup(Group g) => chatSDK.group = g;

    return {
      ChatEventTypes.memberJoined: MemberJoinedHandler(
        coreSDK: chatSDK.coreSDK,
        chatRepository: chatSDK.chatRepository,
        streamManager: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        ownDid: chatSDK.did,
        getGroup: getGroup,
        setGroup: setGroup,
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
        chatId: chatSDK.chatId,
        getGroup: getGroup,
        setGroup: setGroup,
        getChannel: chatSDK.getChannel,
        logger: chatSDK.logger,
      ),
      ChatEventTypes.contactDetailsUpdate: ContactDetailsUpdateHandler(
        chatSDK: chatSDK,
        streamManager: chatSDK.chatStream,
        getGroup: getGroup,
        setGroup: setGroup,
        getChannel: chatSDK.getChannel,
      ),
    };
  }
}
