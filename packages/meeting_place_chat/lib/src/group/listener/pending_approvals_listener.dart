import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import '../control_plane_event_handler/chat_group_invitation_accept_handler.dart';

/// Subscribes to [ControlPlaneEventType.InvitationGroupAccept] events for the
/// current chat. When such an event arrives, the listener applies the resulting
/// group update via [ChatGroupInvitationAcceptHandler] and refreshes the SDK's
/// in-memory [GroupChatSDK.group] and DID cache.
///
/// Intended for use by group owners; the SDK gates the subscription on
/// [GroupChatSDK.isGroupOwner].
class PendingApprovalsListener {
  PendingApprovalsListener(this._chatSDK);

  final GroupChatSDK _chatSDK;

  StreamSubscription<ControlPlaneStreamEvent> listen(Chat chat) {
    return _chatSDK.coreSDK.controlPlaneEventsStream.listen((event) async {
      if (event.type != ControlPlaneEventType.InvitationGroupAccept) return;

      final updatedGroup = await ChatGroupInvitationAcceptHandler(
        coreSDK: _chatSDK.coreSDK,
        chatRepository: _chatSDK.chatRepository,
        streamManager: _chatSDK.chatStream,
        logger: _chatSDK.logger,
      ).handle(event: event, group: _chatSDK.group, chat: chat);

      if (updatedGroup != null) {
        _chatSDK.group = updatedGroup;
        _chatSDK.didCache.registerAll(updatedGroup.members.map((m) => m.did));
      }
    });
  }
}
