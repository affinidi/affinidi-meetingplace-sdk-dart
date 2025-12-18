import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../constants/sdk_constants.dart';
import '../core/chat_history_service.dart';
import '../entity/message.dart' as entity_chat_message;
import '../group/chat_group_details_update_handler.dart';
import '../group/chat_group_member_deregistered_message_handler.dart';
import '../loggers/default_meeting_place_chat_sdk_logger.dart';
import '../utils/top_and_tail_extension.dart';
import 'base_chat_sdk.dart';
import 'chat.dart';
import 'chat_sdk.dart';

/// [GroupChatSDK] is a specialized implementation of [MeetingPlaceChatSDK] for handling
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
    required super.chatRepository,
    required super.options,
    required this.group,
    super.card,
    MeetingPlaceChatSDKLogger? logger,
  }) : _chatHistoryService = ChatHistoryService(
         chatRepository: chatRepository,
         logger:
             logger ??
             DefaultMeetingPlaceChatSDKLogger(
               className: _className,
               sdkName: sdkName,
             ),
       ),
       super(
         logger:
             logger ??
             DefaultMeetingPlaceChatSDKLogger(
               className: _className,
               sdkName: sdkName,
             ),
       );

  static const String _className = 'GroupChatSDK';

  final ChatHistoryService _chatHistoryService;

  Chat? chat;
  Group group;
  StreamSubscription<ControlPlaneStreamEvent>? _controlPlaneSubscription;

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
    final methodName = 'start';
    logger.info('Started group chat', name: methodName);
    if (group.isDeleted) {
      logger.warning('Group chat is deleted', name: methodName);
      return Chat(
        id: chatId,
        stream: null,
        messages: await chatRepository.listMessages(chatId),
      );
    }

    final chat = await super.startChatSession();
    unawaited(sendChatPresence());

    if (_isGroupOwner()) {
      await _createConciergeMessagesForPendingApprovals(chat);

      _controlPlaneSubscription = coreSDK.controlPlaneEventsStream.listen((
        event,
      ) async {
        if (event.type == ControlPlaneEventType.InvitationGroupAccept) {
          if (group.did == event.channel.otherPartyPermanentChannelDid) {
            group = (await coreSDK.getGroupById(group.id))!;
            final conciegeMessages =
                await _createConciergeMessagesForPendingApprovals(chat);
            for (final mes in conciegeMessages) {
              chatStream.pushData(StreamData(chatItem: mes));
            }
          }
        }
      });
    }
    return chat;
  }

  /// Ends the group chat session and cancels any discovery subscriptions.
  @override
  void endChatSession() {
    final methodName = 'end';
    _controlPlaneSubscription?.cancel();

    logger.info('Ended group chat', name: methodName);
    super.end();
  }

  /// Sends a group message via the mediator.
  ///
  /// **Parameters:**
  /// - [message]: The [PlainTextMessage] to send.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [recipientDid]: DID of the recipient of the message.
  /// - [mediatorDid]: DID of the mediator.
  /// - [notify]: Whether to notify group members (default: `false`).
  /// - [ephemeral]: Whether the message is ephemeral (default: `false`).
  /// - [forwardExpiryInSeconds]: Optional duration (in seconds) after which
  /// the forwarded message is considered expired.
  ///
  /// **Returns:**
  /// - A [Future] that completes when the message is sent.
  @override
  Future<void> sendMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required String mediatorDid,
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) {
    final methodName = 'sendMessage';
    logger.info(
      'Send group message of type=${message.type},'
      ' from=${message.from}, to=${message.to}',
      name: methodName,
    );
    return coreSDK.sendGroupMessage(
      message,
      senderDid: senderDid,
      recipientDid: recipientDid,
      increaseSequenceNumber:
          message.type.toString() == ChatProtocol.chatMessage.value,
      notify: notify,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );
  }

  /// Sends a "chat activity" message to the group.
  @override
  Future<void> sendChatActivity() async {
    final methodName = 'sendChatActivity';
    logger.info('Send group chat activity', name: methodName);

    await coreSDK.sendGroupMessage(
      ChatActivity.create(from: did, to: [otherPartyDid]).toPlainTextMessage(),
      senderDid: did,
      recipientDid: otherPartyDid,
      notify: false,
      ephemeral: true,
      increaseSequenceNumber: false,
      forwardExpiryInSeconds: options.chatActivityExpiry.inSeconds,
    );
  }

  /// Checks whether the message type exists in `options.memberJoinedIndicator`.
  bool _memberJoinedIndicator(PlainTextMessage message) {
    return options.memberJoinedIndicator.contains(
      ChatProtocol.byValue(message.type.toString()),
    );
  }

  /// Handles incoming [PlainTextMessage]s that are specific to group chat,
  /// such as:
  /// - Member deregistration
  /// - Group details updates
  /// - Profile hash updates
  /// - Contact details updates
  /// - Alias profile requests
  ///
  /// Updates the group state, repository, and stream manager accordingly.
  Future<void> _handleMessage(PlainTextMessage message) async {
    final methodName = '_handleMessage';
    logger.info('Started handling of group message', name: methodName);

    if (_isGroupOwner() && _memberJoinedIndicator(message)) {
      logger.info(
        'Handling message for member joined event for group owner: '
        '${message.from?.topAndTail()}',
        name: methodName,
      );
      // TODO: keep target list in memory to not always iterate through all
      // messages
      final eventMessages = (await messages).whereType<EventMessage>().toList();
      final matchingMessage = eventMessages.firstWhereOrNull(
        (eventMessage) =>
            eventMessage.status != ChatItemStatus.confirmed &&
            eventMessage.eventType ==
                EventMessageType.awaitingGroupMemberToJoin &&
            (eventMessage.data['memberDid'] == message.from! ||
                eventMessage.data['memberDid'] == message.body?['fromDid']),
      );

      if (matchingMessage != null) {
        logger.info(
          'Matching event message found: '
          'id=${matchingMessage.messageId}, '
          'status=${matchingMessage.status}, '
          'eventType=${matchingMessage.eventType}',
          name: methodName,
        );
        matchingMessage.status = ChatItemStatus.confirmed;
        await chatRepository.updateMesssage(matchingMessage);
        chatStream.pushData(StreamData(chatItem: matchingMessage));

        final chatItem = await _chatHistoryService
            .createGroupMemberJoinedGroupEventMessage(
              chatId: chatId,
              groupDid: group.did,
              memberDid: matchingMessage.data['memberDid'] as String,
              memberCard: ContactCard.fromJson(
                matchingMessage.data['contactCard'] as Map<String, dynamic>,
              ),
            );

        chatStream.pushData(StreamData(chatItem: chatItem));
      }
    }

    if (message.type.toString() ==
        MeetingPlaceProtocol.groupMemberDeregistration.value) {
      logger.info(
        'Handling message for group member deregistered',
        name: methodName,
      );
      group = await ChatGroupMemberDeregisteredMessageHandler(
        coreSDK: coreSDK,
        chatHistoryService: _chatHistoryService,
        streamManager: chatStream,
      ).handle(chatId: chatId, group: group, message: message);
      chatStream.pushData(StreamData(plainTextMessage: message));
    }

    if (message.type.toString() == ChatProtocol.chatGroupDetailsUpdate.value) {
      logger.info(
        'Handling message for group details update',
        name: methodName,
      );
      group = await ChatGroupDetailsUpdateHandler(
        coreSDK: coreSDK,
        chatHistoryService: _chatHistoryService,
        streamManager: chatStream,
      ).handle(group: group, message: message, chatId: chatId);
    }

    if (message.type.toString() == MeetingPlaceProtocol.groupDeletion.value) {
      logger.info(
        'Handling message for group deleted for group ${group.id}',
        name: methodName,
      );
      if (!group.isDeleted) {
        group.markAsDeleted();
        await coreSDK.updateGroup(group);

        final chatItem = await _chatHistoryService
            .createGroupDeletedEventMessage(
              chatId: chatId,
              groupDid: group.did,
            );

        chatStream.pushData(StreamData(chatItem: chatItem));
      }
    }

    if (message.type.toString() == ChatProtocol.chatAliasProfileHash.value) {
      logger.info(
        'Handling message for alias profile hash from'
        ' ${message.from?.topAndTail()}',
        name: methodName,
      );
      final profileHash = message.body?['profile_hash'];
      if (profileHash != null && profileHash is String) {
        final member = group.members.firstWhere(
          (member) => member.did == message.from!,
        );

        if (member.contactCard.profileHash == profileHash) {
          chatStream.pushData(StreamData(plainTextMessage: message));
        } else {
          await coreSDK.sendMessage(
            ChatAliasProfileRequest.create(
              from: did,
              to: [message.from!],
              profileHash: profileHash,
            ).toPlainTextMessage(),
            senderDid: did,
            recipientDid: message.from!,
            mediatorDid: mediatorDid,
          );
        }

        chatStream.pushData(StreamData(plainTextMessage: message));
      } else {
        logger.warning(
          'Skip processing chatAliasProfileHash message '
          'because of empty profile hash',
          name: methodName,
        );
      }
    }

    if (message.type.toString() ==
        ChatProtocol.chatContactDetailsUpdate.value) {
      logger.info(
        'Handling message for contact details update',
        name: methodName,
      );
      final member = group.members.firstWhere(
        (member) => member.did == message.from!,
        orElse: () {
          final message = 'Group member not found';
          logger.error(message, name: methodName);
          throw Exception(message);
        },
      );

      member.contactCard = ContactCard.fromJson(message.body!);
      await coreSDK.updateGroup(group);
      await sendChatGroupDetailsUpdate();
      chatStream.pushData(StreamData(plainTextMessage: message));
    }

    if (message.type.toString() == ChatProtocol.chatAliasProfileRequest.value) {
      logger.info(
        'Handling message for alias profile request',
        name: methodName,
      );
      // Update existing concierge messages -
      // TODO: add concierge message handler
      final targets = (await messages).where(
        (message) =>
            message is ConciergeMessage &&
            message.conciergeType ==
                ConciergeMessageType.permissionToUpdateProfile &&
            message.status == ChatItemStatus.userInput,
      );

      await Future.wait(
        targets.map((t) async {
          t.status = ChatItemStatus.confirmed;
          await chatRepository.updateMesssage(t);
          chatStream.pushData(StreamData(chatItem: t));
        }),
      );

      final conciergeMessage = ConciergeMessage(
        chatId: chatId,
        messageId: const Uuid().v4(),
        senderDid: message.from!,
        isFromMe: false,
        dateCreated: message.createdTime ?? DateTime.now().toUtc(),
        status: ChatItemStatus.userInput,
        conciergeType: ConciergeMessageType.permissionToUpdateProfile,
        data: {
          'profileHash': message.body?['profile_hash'],
          'replyTo': message.from!,
        },
      );

      await chatRepository.createMessage(conciergeMessage);
      chatStream.pushData(
        StreamData(plainTextMessage: message, chatItem: conciergeMessage),
      );
    }

    logger.info('Completed handling of group message', name: methodName);
  }

  /// Fetches new messages from the mediator, processes them,
  ///  and updates the group state.
  ///
  /// **Returns:**
  /// - A list of [Message]s representing newly processed chat messages.
  @override
  Future<List<entity_chat_message.Message>> fetchNewMessages() async {
    final methodName = 'fetchNewMessages';
    logger.info('Started loading new messages', name: methodName);
    final messagesFromMediator = await coreSDK.fetchMessages(
      did: did,
      mediatorDid: mediatorDid,
      // TODO: delete after message has been successfully processed
      deleteOnRetrieve: true,
    );
    final newMessages = <entity_chat_message.Message>[];

    for (final message in messagesFromMediator) {
      await handleMessage(message, newMessages);
      await _handleMessage(message.plainTextMessage);
    }

    logger.info(
      'Completed loading new messages: ${newMessages.length} new messages',
      name: methodName,
    );
    return newMessages;
  }

  /// Subscribes to the mediator channel for group events.
  ///
  /// **Returns:**
  /// - A [MediatorStream] subscription stream for group messages.
  @override
  Future<CoreSDKStreamSubscription> subscribeToMediator() async {
    final methodName = 'subscribeToChannel';
    logger.info('Started subscribing to mediator channel', name: methodName);

    final subscription = await super.subscribeToMediator();
    logger.info('Completed subscribing to group channel', name: methodName);

    subscription.stream.listen((data) async {
      await _handleMessage(data.plainTextMessage);
    });

    return subscription;
  }

  /// Checks if the current user is the group owner.
  ///
  /// **Returns:**
  /// - `true` if the current DID matches the group owner DID,
  ///  otherwise `false`.
  bool _isGroupOwner() {
    return group.ownerDid == did;
  }

  /// Creates concierge messages for members who are pending approval
  /// to join the group.
  ///
  /// **Parameters:**
  /// - [chat]: The current [Chat] instance where messages should be created.
  ///
  /// **Returns:**
  /// - A list of newly created [ConciergeMessage]s.
  Future<List<ConciergeMessage>> _createConciergeMessagesForPendingApprovals(
    Chat chat,
  ) async {
    final methodName = '_createConciergeMessagesForPendingApprovals';
    logger.info(
      'Looking up group members with pending approval status.',
      name: methodName,
    );

    final pendingApprovals = group.getGroupMembersWaitingForApproval();
    final conciergeMessages = <ConciergeMessage>[];

    for (final pendingApproval in pendingApprovals) {
      final existingConciergeMessage = chat.messages.firstWhereOrNull((
        message,
      ) {
        logger.info(
          'Checking for existing concierge message for'
          ' memberDid: ${pendingApproval.did.topAndTail()}',
          name: methodName,
        );
        return message is ConciergeMessage &&
            message.conciergeType ==
                ConciergeMessageType.permissionToJoinGroup &&
            message.data['memberDid'] == pendingApproval.did;
      });

      if (existingConciergeMessage != null) {
        continue;
      }

      final conciergeMessage = ConciergeMessage(
        chatId: chatId,
        messageId: const Uuid().v4(),
        senderDid: pendingApproval.did,
        isFromMe: false,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.userInput,
        conciergeType: ConciergeMessageType.permissionToJoinGroup,
        data: {
          'groupId': group.id,
          'contactCard': pendingApproval.contactCard.toJson(),
          'memberDid': pendingApproval.did,
          'adminDid': group.ownerDid,
          'offerLink': group.offerLink,
        },
      );

      await chatRepository.createMessage(conciergeMessage);
      chat.messages.add(conciergeMessage);
      conciergeMessages.add(conciergeMessage);
    }

    logger.info(
      'Completed creating ${conciergeMessages.length} concierge messages',
      name: methodName,
    );
    return conciergeMessages;
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
    final methodName = 'approveConnectionRequest';
    logger.info('Started approving connection request', name: methodName);
    if (!_isGroupOwner()) {
      final message =
          'Only group owners are allowed to approve connection requests';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    final channel = await coreSDK.getChannelByOtherPartyPermanentDid(
      message.data['memberDid'] as String,
    );

    if (channel == null) {
      final message = 'Channel does not exist';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    // TODO: temporary solution as long as approveConnectionRequest requires
    // connectionOffer
    final connectionOffer = await coreSDK.getConnectionOffer(channel.offerLink);
    if (connectionOffer == null) {
      final message = 'Connection offer connected to channel not found.';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    await coreSDK.approveConnectionRequest(channel: channel);

    // Refresh group due to changes within SDK
    group = (await coreSDK.getGroupById(group.id))!;
    await sendChatGroupDetailsUpdate();

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    chatStream.pushData(StreamData(chatItem: message));

    final chatItem = await _chatHistoryService
        .createAwaitingGroupMemberToJoinEventMessage(
          chatId: chatId,
          groupDid: group.did,
          memberDid: channel.otherPartyPermanentChannelDid!,
          memberCard: channel.otherPartyContactCard!,
        );

    logger.info(
      'Completed approving connection request for member: '
      '${channel.otherPartyPermanentChannelDid?.topAndTail()}',
      name: methodName,
    );
    chatStream.pushData(StreamData(chatItem: chatItem));
  }

  /// Sends a profile hash message to the group owner if the current contact card
  /// has changed since the last update.
  @override
  Future<void> sendProfileHash() async {
    final methodName = 'sendProfileHash';
    logger.info('Started sending profile hash', name: methodName);
    if (card == null) {
      logger.warning(
        'ContactCard is null. Skipping sending profile hash message.',
        name: methodName,
      );
      return;
    }

    final channel = await getChannel();
    if (channel.contactCard == null || card!.equals(channel.contactCard!)) {
      return;
    }

    if (!_isGroupOwner()) {
      await coreSDK.sendMessage(
        ChatAliasProfileHash.create(
          from: did,
          to: [group.ownerDid!],
          profileHash: card!.profileHash,
        ).toPlainTextMessage(),
        senderDid: did,
        recipientDid: group.ownerDid!,
        mediatorDid: mediatorDid,
      );

      channel.contactCard = card;
      await coreSDK.updateChannel(channel);
      return;
    }

    final targets = (await messages).where(
      (message) =>
          message is ConciergeMessage &&
          message.conciergeType ==
              ConciergeMessageType.permissionToUpdateProfile &&
          message.status == ChatItemStatus.userInput,
    );

    await Future.wait(
      targets.map((t) async {
        t.status = ChatItemStatus.confirmed;
        await chatRepository.updateMesssage(t);
        chatStream.pushData(StreamData(chatItem: t));
      }),
    );

    final conciergeMessage = ConciergeMessage(
      chatId: chatId,
      messageId: const Uuid().v4(),
      senderDid: did,
      isFromMe: false,
      dateCreated: DateTime.now().toUtc(),
      status: ChatItemStatus.userInput,
      conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      data: {'profileDetails': card!.toJson(), 'replyTo': otherPartyDid},
    );

    await chatRepository.createMessage(conciergeMessage);
    logger.info('Completed sending profile hash', name: methodName);

    channel.contactCard = card;
    await coreSDK.updateChannel(channel);
    chatStream.pushData(StreamData(chatItem: conciergeMessage));
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
    final methodName = 'rejectConnectionRequest';
    logger.info('Started rejecting connection request', name: methodName);
    if (!_isGroupOwner()) {
      final message =
          'Only group owners are allowed to reject connection requests';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    final channel = await coreSDK.getChannelByDid(
      message.data['memberDid'] as String,
    );
    if (channel == null) {
      final message = 'Channel does not exist';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    group = await coreSDK.rejectConnectionRequest(channel: channel);
    await sendChatGroupDetailsUpdate();

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);
    logger.info(
      'Completed rejecting connection request for member: '
      '${channel.otherPartyPermanentChannelDid?.topAndTail()}',
      name: methodName,
    );
    chatStream.pushData(StreamData(chatItem: message));
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
    final methodName = 'sendChatContactDetailsUpdate';
    logger.info(
      'Started sending chat contact details update',
      name: methodName,
    );
    if (card == null) {
      final message = 'ContactCard missing for contact details update';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    if (_isGroupOwner()) {
      final myMember = group.members.firstWhere((m) => m.did == did);
      myMember.contactCard = card!;

      await coreSDK.updateGroup(group);
      unawaited(sendChatGroupDetailsUpdate());
    } else {
      unawaited(
        coreSDK.sendMessage(
          ChatContactDetailsUpdate.create(
            from: did,
            to: [message.data['replyTo'] as String],
            profileDetails: card!.toJson(),
          ).toPlainTextMessage(),
          senderDid: did,
          recipientDid: message.data['replyTo'] as String,
          mediatorDid: mediatorDid,
        ),
      );
    }

    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);

    logger.info(
      'Completed sending chat contact details update',
      name: methodName,
    );
    chatStream.pushData(StreamData(chatItem: message));
  }

  /// Sends a group details update message to synchronize state
  /// across all members.
  Future<void> sendChatGroupDetailsUpdate() async {
    final methodName = 'sendChatGroupDetailsUpdate';
    logger.info('Started sending chat group details update', name: methodName);
    unawaited(
      sendMessage(
        ChatGroupDetailsUpdate.fromGroup(
          group,
          senderDid: did,
        ).toPlainTextMessage(),
        senderDid: did,
        recipientDid: otherPartyDid,
        mediatorDid: mediatorDid,
      ),
    );
    logger.info(
      'Completed sending chat group details update',
      name: methodName,
    );
  }
}
