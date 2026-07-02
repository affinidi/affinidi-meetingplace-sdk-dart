import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../factory/pending_approval_concierge_factory.dart';
import '../group_matrix_chat_sdk.dart';

/// Subscribes to [ControlPlaneEventType.InvitationGroupAccept] events for the
/// current chat. When such an event arrives, the listener refreshes the group,
/// creates concierge messages for pending approvals, and updates the SDK's
/// in-memory [GroupMatrixChatSDK.group] and DID cache.
///
/// Intended for use by group owners; the SDK gates the subscription on
/// [GroupMatrixChatSDK.isGroupOwner].
class PendingApprovalsListener {
  PendingApprovalsListener(this._chatSDK);

  final GroupMatrixChatSDK _chatSDK;

  StreamSubscription<ControlPlaneStreamEvent> listen(Chat chat) {
    return _chatSDK.coreSDK.controlPlaneEventsStream.listen((event) async {
      if (event.type != ControlPlaneEventType.InvitationGroupAccept) return;

      final group = _chatSDK.group;
      if (group.did != event.channel.otherPartyPermanentChannelDid) return;

      final updatedGroup = (await _chatSDK.coreSDK.getGroupById(group.id))!;

      final conciergeMessages = await PendingApprovalConciergeFactory(
        chatRepository: _chatSDK.chatRepository,
        logger: _chatSDK.logger,
      ).create(group: updatedGroup, chat: chat);

      for (final message in conciergeMessages) {
        _chatSDK.chatStream.pushData(StreamData(chatItem: message));
      }

      _chatSDK.group = updatedGroup;
    });
  }
}
