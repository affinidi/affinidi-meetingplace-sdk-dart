import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../transport/matrix/incoming/incoming_room_event_router.dart';
import '../matrix_chat_sdk.dart';
import 'action/approve_connection_request_action.dart';
import 'action/propose_profile_update_action.dart';
import 'action/reject_connection_request_action.dart';
import 'action/remove_member_action.dart';
import 'factory/pending_approval_concierge_factory.dart';
import 'group_room_event_router.dart';
import 'listener/pending_approvals_listener.dart';

/// [GroupMatrixChatSDK] is a specialized implementation of
/// [MeetingPlaceChatSDK] for handling **group chat functionality** in the
/// Meeting Place SDK.
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
class GroupMatrixChatSDK extends MatrixChatSDK implements MeetingPlaceChatSDK {
  GroupMatrixChatSDK({
    required super.coreSDK,
    required super.did,
    required super.otherPartyDid,
    required super.mediatorDid,
    required super.chatRepository,
    required super.options,
    required this.group,
    super.card,
    super.logger,
  });

  /// Log key for consistent logging across methods in this class.
  static const String _logkey = 'GroupMatrixChatSDK';

  @override
  TransportCapabilities get capabilities => _capabilities;

  /// Per-chat features supported by a group chat. Group chats always use the
  /// Matrix transport and share the individual Matrix feature set. Group
  /// membership itself is a property of the channel, not a gated chat feature.
  static const _capabilities = TransportCapabilities({
    ChatFeature.textMessaging,
    ChatFeature.mediaAttachments,
    ChatFeature.documentAttachments,
    ChatFeature.voiceMessages,
    ChatFeature.reactions,
    ChatFeature.typingIndicators,
    ChatFeature.deliveryReceipts,
    ChatFeature.messageEdit,
    ChatFeature.messageDelete,
    ChatFeature.effects,
    ChatFeature.contactDetailsUpdate,
  });

  @override
  @protected
  IncomingRoomEventRouter buildRoomEventRouter() =>
      GroupRoomEventRouter(chatSDK: this);

  @override
  @protected
  void assertCanSend() {
    if (group.isDeleted) {
      throw StateError('Cannot send messages: group has been deleted');
    }
  }

  @override
  @protected
  ChannelNotification buildChannelNotification(String type) =>
      GroupChannelNotification(
        offerLink: group.offerLink,
        groupDid: group.did,
        type: type,
      );

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

  /// Removes [memberDid] from the group. Owner-only.
  ///
  /// Drives the kick + deregistration through the core SDK and updates local
  /// chat state directly so the initiator's UI reflects the change without
  /// waiting for a Matrix echo (which is filtered by `excludeSelf`).
  @override
  Future<void> removeMember(String memberDid) async {
    group = await RemoveMemberAction(this, memberDid: memberDid).execute();
  }

  /// Creates a local concierge prompting the user to confirm sharing the new
  /// contact card with the group. The card is broadcast to the group only when
  /// the user approves via [sendChatContactDetailsUpdate].
  @override
  Future<void> proposeProfileUpdate() async {
    assertCanSend();
    await ProposeProfileUpdateAction(this).execute();
    logger.info('Proposed profile update', name: _logkey);
  }

  /// Sends updated chat contact details to other group members.
  ///
  /// Mirrors the new card into the local group state and persists the group
  /// before delegating to the Matrix transport (see
  /// [MatrixChatSDK.sendChatContactDetailsUpdate]) for the wire
  /// dispatch and message status update.
  ///
  /// **Throws:**
  /// - [StateError] if [card] is missing.
  @override
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {
    assertCanSend();
    final c = card;
    if (c == null) {
      throw StateError('ContactCard missing for contact details update');
    }
    final myMember = group.members.firstWhere((m) => m.did == did);
    myMember.contactCard = c;
    await coreSDK.updateGroup(group);

    await super.sendChatContactDetailsUpdate(message);
  }

  Future<List<ChatItem>> _createConciergeMessagesForPendingApprovals(
    Chat chat,
  ) => PendingApprovalConciergeFactory(
    chatRepository: chatRepository,
    logger: logger,
  ).create(group: group, chat: chat);
}
