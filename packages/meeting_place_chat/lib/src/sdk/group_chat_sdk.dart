import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../constants/sdk_constants.dart';
import '../core/chat_history_service.dart';
import '../entity/message.dart' as entity_chat_message;
import '../group/chat_group_alias_profile_hash_handler.dart';
import '../group/chat_group_alias_profile_request_handler.dart';
import '../group/chat_group_contact_details_update_handler.dart';
import '../group/chat_group_deletion_handler.dart';
import '../group/chat_group_details_update_handler.dart';
import '../group/chat_group_member_deregistered_message_handler.dart';
import '../group/chat_group_member_joined_handler.dart';
import '../loggers/default_meeting_place_chat_sdk_logger.dart';
import '../utils/top_and_tail_extension.dart';
import 'base_chat_sdk.dart';
import 'chat.dart';

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
  Future<void> endChatSession() async {
    final methodName = 'end';
    unawaited(_controlPlaneSubscription?.cancel());

    logger.info('Ended group chat', name: methodName);
    await super.end();
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
  Future<void> sendPlainTextMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required String mediatorDid,
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) {
    final methodName = 'sendPlainTextMessage';
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

  /// Map of protocol type to handler callbacks for group message dispatch.
  Map<String, Future<bool> Function(PlainTextMessage)>
  get _groupMessageHandlers => {
    MeetingPlaceProtocol.groupMemberDeregistration.value: (msg) async {
      group = await ChatGroupMemberDeregisteredMessageHandler(
        coreSDK: coreSDK,
        chatHistoryService: _chatHistoryService,
        streamManager: chatStream,
      ).handle(chatId: chatId, group: group, message: msg);
      chatStream.pushData(StreamData(plainTextMessage: msg));
      return true;
    },
    ChatProtocol.chatGroupDetailsUpdate.value: (msg) async {
      group = await ChatGroupDetailsUpdateHandler(
        coreSDK: coreSDK,
        chatHistoryService: _chatHistoryService,
        streamManager: chatStream,
      ).handle(group: group, message: msg, chatId: chatId);
      return true;
    },
    MeetingPlaceProtocol.groupDeletion.value: (msg) async {
      group = await ChatGroupDeletionHandler(
        coreSDK: coreSDK,
        chatHistoryService: _chatHistoryService,
        streamManager: chatStream,
      ).handle(group: group, message: msg, chatId: chatId);
      return true;
    },
    ChatProtocol.chatAliasProfileHash.value: (msg) async {
      await ChatGroupAliasProfileHashHandler(
        chatSDK: this,
        streamManager: chatStream,
      ).handle(group: group, message: msg);
      return true;
    },
    ChatProtocol.chatContactDetailsUpdate.value: (msg) async {
      group = await ChatGroupContactDetailsUpdateHandler(
        chatSDK: this,
        streamManager: chatStream,
      ).handle(group: group, message: msg);
      return true;
    },
    ChatProtocol.chatAliasProfileRequest.value: (msg) async {
      await ChatGroupAliasProfileRequestHandler(
        chatRepository: chatRepository,
        streamManager: chatStream,
      ).handle(message: msg, chatId: chatId);
      return true;
    },
  };

  /// Handles incoming [PlainTextMessage]s that are specific to group chat,
  /// such as:
  /// - Member deregistration
  /// - Group details updates
  /// - Group deletion
  /// - Profile hash updates
  /// - Contact details updates
  /// - Alias profile requests
  ///
  /// Updates the group state, repository, and stream manager accordingly.
  Future<bool> _handleMessage(MediatorMessage message) async {
    final methodName = '_handleMessage';
    logger.info('Started handling of group message', name: methodName);

    final plainTextMessage = message.plainTextMessage;

    await ChatGroupMemberJoinedHandler(
      chatRepository: chatRepository,
      chatHistoryService: _chatHistoryService,
      streamManager: chatStream,
    ).handle(
      chatId: chatId,
      groupDid: group.did,
      isGroupOwner: _isGroupOwner(),
      memberJoinedIndicator: options.memberJoinedIndicator,
      message: message,
    );

    final messageType = plainTextMessage.type.toString();
    final handler = _groupMessageHandlers[messageType];
    if (handler != null) {
      logger.info(
        'Handling group message of type $messageType',
        name: methodName,
      );
      return handler(plainTextMessage);
    }

    logger.info('Completed handling of group message', name: methodName);
    return false;
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
      deleteOnRetrieve: false,
    );
    final newMessages = <entity_chat_message.Message>[];
    final processedHashes = <String>[];

    for (final message in messagesFromMediator) {
      final messageHandled = await handleMessage(message, newMessages);
      final messageHandledInternal = await _handleMessage(message);

      if (!messageHandledInternal && !messageHandled) {
        chatStream.pushData(
          StreamData(plainTextMessage: message.plainTextMessage),
        );
      }
      processedHashes.add(message.messageHash!);
    }

    if (processedHashes.isNotEmpty) {
      await coreSDK.deleteMessages(
        did: did,
        mediatorDid: mediatorDid,
        messageHashes: processedHashes,
      );
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
  /// - A [SDKStreamSubscription] subscription stream for group messages.
  @override
  Future<SDKStreamSubscription> subscribeToMediator() async {
    final methodName = 'subscribeToChannel';
    logger.info('Started subscribing to mediator channel', name: methodName);

    final subscription = await super.subscribeToMediator();
    logger.info('Completed subscribing to group channel', name: methodName);

    subscription.listen((data) async {
      if (!await _handleMessage(data)) {
        chatStream.pushData(
          StreamData(plainTextMessage: data.plainTextMessage),
        );
      }
      return MediatorStreamProcessingResult(keepMessage: false);
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
      await sendDirectMessage(
        ChatAliasProfileHash.create(
          from: did,
          to: [group.ownerDid!],
          profileHash: card!.profileHash,
        ).toPlainTextMessage(),
        recipientDid: group.ownerDid!,
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
      final replyTo = message.data['replyTo'] as String;
      unawaited(
        sendDirectMessage(
          ChatContactDetailsUpdate.create(
            from: did,
            to: [replyTo],
            profileDetails: card!.toJson(),
          ).toPlainTextMessage(),
          recipientDid: replyTo,
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
      sendPlainTextMessage(
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
