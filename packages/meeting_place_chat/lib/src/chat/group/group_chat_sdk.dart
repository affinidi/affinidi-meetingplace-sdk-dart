import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../../meeting_place_chat.dart';
import '../../transport/matrix/outgoing/outgoing.dart';
import 'action/approve_connection_request_action.dart';
import 'action/propose_profile_update_action.dart';
import 'action/reject_connection_request_action.dart';
import 'action/send_chat_contact_details_update_action.dart';
import 'factory/pending_approval_concierge_factory.dart';
import 'listener/pending_approvals_listener.dart';
import '../base_chat_sdk.dart';
import 'group_room_event_router.dart';
import '../../transport/matrix/incoming/incoming_room_event_router.dart';

/// [GroupChatSDK] is a specialized implementation of [MeetingPlaceChatSDK] for
/// handling
/// **group chat functionality** in the Meeting Place SDK.
///
/// Built on top of [BaseChatSDK], it leverages:
/// - **Decentralised Identifiers (DIDs)** for a globally unique
///   identifierfor secure interactions.
/// - **DIDComm Messaging v2.1 protocol** for a secure, private,
///   and trusted communications across systems.
///
/// Responsibilities:
/// - Managing group membership approvals/rejections.
/// - Handling concierge messages for join requests or profile updates.
/// - Subscribing to group discovery events.
/// - Sending group messages, activities, and profile updates.
class GroupChatSDK extends BaseChatSDK implements ChatSDK {
  GroupChatSDK({
    required super.coreSDK,
    required super.did,
    required super.otherPartyDid,
    required super.mediatorDid,
    required super.roomId,
    required super.chatRepository,
    required super.options,
    required this.group,
    super.card,
    super.logger,
  });

  /// Log key for consistent logging across methods in this class.
  static const String _logkey = 'GroupChatSDK';

  @override
  @protected
  IncomingRoomEventRouter buildRoomEventRouter() =>
      GroupRoomEventRouter(chatSDK: this);

  /// The current state of the group, which may be updated over time as events
  /// are received.
  Group group;

  /// Subscription to control plane events, used for listening to incoming
  /// pending approval requests when the current user is the group owner.
  StreamSubscription<ControlPlaneStreamEvent>? _controlPlaneSubscription;

  /// Checks if the current user is the group owner.
  ///
  /// **Returns:**
  /// - `true` if the current DID matches the group owner DID,
  ///  otherwise `false`.
  bool get isGroupOwner => group.ownerDid == did;

  /// Starts a group chat session.
  ///
  /// If the current user is the group owner, it:
  /// - Creates concierge messages for pending approvals.
  /// - Listens for [ControlPlaneEventType.InvitationGroupAccept] events and
  ///   updates the group state accordingly.
  ///
  /// **Returns:**
  /// - A [Chat] instance representing the started session.
  @override
  Future<Chat> startChatSession() async {
    if (group.isDeleted) {
      logger.info('Group has been deleted', name: _logkey);
      final messages = await chatRepository.listMessages(chatId);
      return Chat.deleted(id: chatId, messages: messages);
    }

    didCache.registerAll(group.members.map((m) => m.did));
    logger.info('DIDs registered for group ID: ${group.id}', name: _logkey);

    final chat = await super.startChatSession();

    if (isGroupOwner) {
      await _createConciergeMessagesForPendingApprovals(chat);
      _controlPlaneSubscription = PendingApprovalsListener(this).listen(chat);
    }

    return chat;
  }

  /// End the chat session, cancelling any active subscriptions and cleaning up
  /// resources.
  @override
  Future<void> endChatSession() async {
    unawaited(_controlPlaneSubscription?.cancel());
    await super.end();
    logger.info('Group chat ended', name: _logkey);
  }

  /// Approves a pending connection request for joining the group.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] requesting approval.
  ///
  /// **Throws:**
  /// - [Exception] if the caller is not the group owner.
  /// - [Exception] if the channel or connection offer cannot be found.
  @override
  Future<void> approveConnectionRequest(ConciergeMessage message) async {
    group = await ApproveConnectionRequestAction(
      this,
      message: message,
    ).execute();
  }

  /// Rejects a pending connection request for joining the group.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] requesting approval.
  ///
  /// **Throws:**
  /// - [Exception] if the caller is not the group owner.
  /// - [Exception] if the channel does not exist.
  @override
  Future<void> rejectConnectionRequest(ConciergeMessage message) async {
    group = await RejectConnectionRequestAction(
      this,
      message: message,
    ).execute();
  }

  /// Sends a "chat activity" (typing indicator) to the group via Matrix
  /// ephemeral typing notification.
  @override
  Future<void> sendChatActivity() async {
    await coreSDK.sendMessage(
      ChatTypingNotification(
        senderDid: did,
        roomId: roomId,
        active: true,
        timeoutMs: options.chatActivityExpiry.inMilliseconds,
      ),
    );

    logger.info('Sent chat activity', name: _logkey);
  }

  /// Dispatches an arbitrary Matrix room event into the group's room.
  ///
  /// Low-level escape hatch: the SDK does not persist a [ChatItem] or push to
  /// [chatStream] for the sender. Receivers handle the event through their
  /// existing incoming routers based on [CustomRoomEvent.type].
  Future<void> sendRoomEvent(CustomRoomEvent event) async {
    await coreSDK.sendMessage(
      MatrixCustomOutgoingMessage(
        senderDid: did,
        roomId: roomId,
        type: event.type,
        content: event.content,
      ),
    );

    logger.info('Sent custom room event of type ${event.type}', name: _logkey);
  }

  /// Creates a local concierge prompting the user to confirm sharing the new
  /// contact card with the group. The card is broadcast to the group only when
  /// the user approves via [sendChatContactDetailsUpdate].
  @override
  Future<void> proposeProfileUpdate() async {
    await ProposeProfileUpdateAction(this).execute();
    logger.info('Proposed profile update', name: _logkey);
  }

  /// Sends updated chat contact details to another member in the group.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] representing the update request.
  ///
  /// **Throws:**
  /// - [Exception] if [card] is missing.
  @override
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {
    await SendChatContactDetailsUpdateAction(this).execute(message);
    logger.info('Sent chat contact details update', name: _logkey);
  }

  Future<List<ChatItem>> _createConciergeMessagesForPendingApprovals(
    Chat chat,
  ) => PendingApprovalConciergeFactory(
    chatRepository: chatRepository,
    logger: logger,
  ).create(group: group, chat: chat);
}
