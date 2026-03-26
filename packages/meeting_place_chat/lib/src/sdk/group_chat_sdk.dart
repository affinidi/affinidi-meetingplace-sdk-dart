import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../constants/sdk_constants.dart';
import '../core/chat_history_service.dart';
import '../entity/message.dart' as entity_chat_message;
import '../group/chat_group_details_update_handler.dart';
import '../group/chat_group_member_deregistered_message_handler.dart';
import '../loggers/default_meeting_place_chat_sdk_logger.dart';
import '../utils/attachment_extension.dart';
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
  StreamSubscription<List<String>>? _matrixTypingSubscription;
  StreamSubscription<matrix.CachedPresence>? _matrixPresenceSubscription;
  bool _isSendingChatPresence = false;

  Future<void> _refreshGroupOwnerState({required String trigger}) async {
    try {
      logger.info(
        'Refreshing group owner state after $trigger for group=${group.id}',
        name: _className,
      );
      final refreshedGroup = await coreSDK.getGroupById(group.id);
      if (refreshedGroup == null) {
        logger.warning(
          'Group owner state refresh after $trigger skipped because the group was not found for group=${group.id}',
          name: _className,
        );
        return;
      }

      group = refreshedGroup;

      final matrixRoomId = group.matrixRoomId;
      if (matrixRoomId == null || matrixRoomId.trim().isEmpty) {
        logger.warning(
          'Group owner state refresh after $trigger skipped Matrix sync because matrixRoomId is empty for group=${group.id}',
          name: _className,
        );
        return;
      }

      logger.info(
        'Refreshing Matrix room state after $trigger for room=${matrixRoomId.topAndTail()} group=${group.id}',
        name: _className,
      );
      await coreSDK.syncMatrixRoom(did: did, roomId: matrixRoomId);
      logger.info(
        'Completed Matrix room refresh after $trigger for room=${matrixRoomId.topAndTail()} group=${group.id}',
        name: _className,
      );
    } catch (e, st) {
      logger.error(
        'Failed to refresh group owner state after $trigger. Continuing with existing group state.',
        error: e,
        stackTrace: st,
        name: _className,
      );
    }
  }

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

    if (_isGroupOwner()) {
      unawaited(_refreshGroupOwnerState(trigger: 'group chat startup'));
    }

    // Keep Matrix presence fresh while the group chat is open.
    unawaited(startChatPresenceUpdates());

    final matrixRoomId = group.matrixRoomId;

    // Build mxid→DID map first so both typing and presence events carry DIDs.
    unawaited(() async {
      try {
        final mxidToDid = <String, String>{};
        for (final member in group.members) {
          if (member.did == did) continue;
          final mxid = await coreSDK.matrixUserIdForDid(
            did: did,
            targetDid: member.did,
          );
          mxidToDid[mxid] = member.did;
        }

        if (matrixRoomId != null && matrixRoomId.trim().isNotEmpty) {
          _matrixTypingSubscription = coreSDK
              .subscribeToMatrixTyping(did: did, roomId: matrixRoomId)
              .listen((typingUserIds) {
                final now = DateTime.now().toUtc();
                // Skip own/unknown mxids; use first that resolves to a known DID.
                final senderDid = typingUserIds
                    .map((mxid) => mxidToDid[mxid])
                    .whereType<String>()
                    .firstOrNull;
                chatStream.pushData(
                  StreamData(
                    plainTextMessage: PlainTextMessage(
                      id: const Uuid().v4(),
                      type: Uri.parse(ChatProtocol.chatActivity.value),
                      from: typingUserIds.isEmpty ? null : senderDid,
                      to: [group.did],
                      body: {'timestamp': now.toIso8601String()},
                      createdTime: now,
                    ),
                  ),
                );
              });
        }

        if (mxidToDid.isEmpty) return;

        _matrixPresenceSubscription = coreSDK
            .subscribeToMatrixPresence(
              did: did,
              userIds: mxidToDid.keys.toSet(),
            )
            .listen((presence) {
              final memberDid = mxidToDid[presence.userid] ?? presence.userid;
              final now = DateTime.now().toUtc();
              chatStream.pushData(
                StreamData(
                  plainTextMessage: PlainTextMessage(
                    id: const Uuid().v4(),
                    type: Uri.parse(ChatProtocol.chatPresence.value),
                    from: memberDid,
                    to: [group.did],
                    body: {
                      'timestamp': now.toIso8601String(),
                      'presence': presence.presence.name,
                      if (presence.statusMsg != null)
                        'statusMsg': presence.statusMsg,
                      if (presence.currentlyActive != null)
                        'currentlyActive': presence.currentlyActive,
                      if (presence.lastActiveTimestamp != null)
                        'lastActiveTimestamp': presence.lastActiveTimestamp!
                            .toIso8601String(),
                    },
                    createdTime: now,
                  ),
                ),
              );
            });

        // Seed the initial presence state from the client's in-memory cache.
        // `onPresenceChanged` only fires on NEW events, so without this seed
        // any member who was already online before this screen opened would
        // never be shown as online until the next sync cycle.
        final cached = await coreSDK.getMatrixPresenceForUsers(
          did: did,
          userIds: mxidToDid.keys.toSet(),
        );
        for (final presence in cached) {
          final memberDid = mxidToDid[presence.userid] ?? presence.userid;
          final now = DateTime.now().toUtc();
          chatStream.pushData(
            StreamData(
              plainTextMessage: PlainTextMessage(
                id: const Uuid().v4(),
                type: Uri.parse(ChatProtocol.chatPresence.value),
                from: memberDid,
                to: [group.did],
                body: {
                  'timestamp': now.toIso8601String(),
                  'presence': presence.presence.name,
                  if (presence.statusMsg != null)
                    'statusMsg': presence.statusMsg,
                  if (presence.currentlyActive != null)
                    'currentlyActive': presence.currentlyActive,
                  if (presence.lastActiveTimestamp != null)
                    'lastActiveTimestamp': presence.lastActiveTimestamp!
                        .toIso8601String(),
                },
                createdTime: now,
              ),
            ),
          );
        }
      } catch (e) {
        logger.warning(
          'Failed to subscribe to Matrix presence notifications: $e',
          name: methodName,
        );
      }
    }());

    if (_isGroupOwner()) {
      unawaited(() async {
        final conciergeMessages =
            await _createConciergeMessagesForPendingApprovals(chat);
        for (final message in conciergeMessages) {
          chatStream.pushData(StreamData(chatItem: message));
        }
      }());

      _controlPlaneSubscription = coreSDK.controlPlaneEventsStream.listen((
        event,
      ) async {
        if (event.type == ControlPlaneEventType.InvitationGroupAccept) {
          if (group.did == event.channel.otherPartyPermanentChannelDid) {
            await _refreshGroupOwnerState(trigger: 'InvitationGroupAccept');
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

  @override
  Future<String?> matrixRoomIdForTimelineFiltering() async {
    return group.matrixRoomId;
  }

  /// Ends the group chat session and cancels any discovery subscriptions.
  @override
  Future<void> endChatSession() async {
    final methodName = 'end';
    unawaited(_controlPlaneSubscription?.cancel());
    unawaited(_matrixTypingSubscription?.cancel());
    unawaited(_matrixPresenceSubscription?.cancel());

    stopChatPresenceInterval();

    logger.info('Ended group chat', name: methodName);
    await sendOfflinePresence();

    // Send a "not typing" ephemeral event to the group room.
    // This breaks other members' long-poll /sync requests (up to 30s) causing
    // them to immediately receive the above offline presence update rather than
    // waiting for the next sync cycle.
    final matrixRoomId = group.matrixRoomId;
    if (matrixRoomId != null && matrixRoomId.trim().isNotEmpty) {
      try {
        await coreSDK.setMatrixTyping(
          did: did,
          roomId: matrixRoomId,
          isTyping: false,
        );
      } catch (e) {
        logger.warning(
          'Failed to send typing-stop signal on chat exit: $e',
          name: methodName,
        );
      }
    }

    await super.end();
  }

  /// Starts the periodic sending of chat presence signals.
  ///
  /// Interval can be configured via [options.chatPresenceSendInterval] in [ChatSDKOptions].
  @override
  Future<void> startChatPresenceUpdates() async =>
      _startChatPresenceInInterval(options.chatPresenceSendInterval.inSeconds);

  Future<void> _startChatPresenceInInterval(int intervalInSeconds) async {
    if (_isSendingChatPresence) return;

    _isSendingChatPresence = true;
    while (_isSendingChatPresence) {
      try {
        await sendChatPresence();
        await Future<void>.delayed(Duration(seconds: intervalInSeconds));
      } catch (e) {
        logger.error('Error sending chat presence signal: $e');
        stopChatPresenceInterval();
      }
    }
  }

  void stopChatPresenceInterval() {
    _isSendingChatPresence = false;
  }

  @override
  Future<Message> downloadAttachment({
    required String messageId,
    required String attachmentId,
  }) async {
    final methodName = 'downloadAttachment';
    logger.info(
      'Started downloading attachment $attachmentId for message $messageId',
      name: methodName,
    );

    final chatItem = await chatRepository.getMessage(
      chatId: chatId,
      messageId: messageId,
    );

    if (chatItem is! Message) {
      final message = 'Message $messageId not found or is not a chat message';
      logger.error(message, name: methodName);
      throw StateError(message);
    }

    final attachmentIndex = chatItem.attachments.indexWhere(
      (attachment) => attachment.id == attachmentId,
    );
    if (attachmentIndex < 0) {
      final message =
          'Attachment $attachmentId not found in message $messageId';
      logger.error(message, name: methodName);
      throw StateError(message);
    }

    final existingAttachment = chatItem.attachments[attachmentIndex];
    final existingBase64 = existingAttachment.data?.base64;
    if (existingBase64 != null && existingBase64.trim().isNotEmpty) {
      chatStream.pushData(StreamData(chatItem: chatItem));
      logger.info(
        'Attachment $attachmentId already has base64 data; emitted stream event without downloading',
        name: methodName,
      );
      return chatItem;
    }

    try {
      final updatedAttachment = await coreSDK.downloadAttachment(
        did: did,
        attachment: existingAttachment,
      );

      final updatedAttachments = [...chatItem.attachments];
      updatedAttachments[attachmentIndex] = updatedAttachment;

      final updatedMessage = Message(
        chatId: chatItem.chatId,
        messageId: chatItem.messageId,
        senderDid: chatItem.senderDid,
        value: chatItem.value,
        isFromMe: chatItem.isFromMe,
        dateCreated: chatItem.dateCreated,
        status: chatItem.status,
        type: chatItem.type,
        attachments: updatedAttachments,
        reactions: chatItem.reactions,
      );

      await chatRepository.updateMesssage(updatedMessage);
      chatStream.pushData(StreamData(chatItem: updatedMessage));

      logger.info(
        'Completed downloading attachment $attachmentId for message $messageId',
        name: methodName,
      );
      return updatedMessage;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to download attachment $attachmentId for message $messageId',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(e, stackTrace);
    }
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
    List<String>? mentionUserIds,
  }) {
    final methodName = 'sendPlainTextMessage';
    logger.info(
      'Send group message of type=${message.type},'
      ' from=${message.from}, to=${message.to}',
      name: methodName,
    );

    if (message.isOfType(ChatProtocol.chatMessage.value)) {
      return coreSDK.sendGroupMessageOverMatrix(
        roomId: group.matrixRoomId!,
        message: message.body?['text'] ?? '',
        senderDid: senderDid,
        recipientDid: recipientDid,
        notify: notify,
        mentionUserIds: mentionUserIds,
      );
    }

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
    logger.info('Set MATRIX typing', name: methodName);

    final matrixRoomId = group.matrixRoomId;
    if (matrixRoomId == null || matrixRoomId.trim().isEmpty) {
      logger.warning(
        'Group does not have a Matrix room ID; skipping Matrix typing notification.',
        name: methodName,
      );
      return;
    }

    try {
      await coreSDK.setMatrixTyping(
        did: did,
        roomId: matrixRoomId,
        isTyping: true,
        timeoutMs: options.chatActivityExpiry.inMilliseconds,
      );
    } catch (e) {
      logger.warning(
        'Failed to send Matrix typing notification: $e',
        name: methodName,
      );
    }
  }

  /// Reacts on a message using Matrix `m.reaction` events.
  ///
  /// Group chats have a stable Matrix room ID, so we can send reactions
  /// directly to that room.
  @override
  Future<void> reactOnMessage(
    Message message, {
    required String reaction,
  }) async {
    final methodName = 'reactOnMessage';
    logger.info('Started reacting on message (Matrix/group)', name: methodName);

    final matrixRoomId = group.matrixRoomId;
    if (matrixRoomId == null || matrixRoomId.trim().isEmpty) {
      logger.warning(
        'Group does not have a Matrix room ID; cannot send Matrix reaction.',
        name: methodName,
      );
      return;
    }

    if (!message.messageId.startsWith(r'$')) {
      logger.warning(
        'Skipping reaction for non-Matrix messageId=${message.messageId.topAndTail()} '
        '(expected Matrix event IDs to start with \$).',
        name: methodName,
      );
      return;
    }

    await sendMatrixReaction(
      message: message,
      reaction: reaction,
      roomId: matrixRoomId,
    );

    logger.info(
      'Completed reacting on message (Matrix/group)',
      name: methodName,
    );
  }

  /// Sends a plain text message with optional attachments to the group.
  ///
  /// If attachments include base64 payloads or Matrix `mxc://` links, they will
  /// be sent over Matrix and normalised as attachments whose `data.links`
  /// contain the Matrix media URI.
  ///
  /// **Parameters:**
  /// - [text]: The plain text content of the message (default: empty string for media-only messages).
  /// - [attachments]: Optional list of [Attachment]s included with the message.
  ///
  /// **Returns:**
  /// - The sent [Message] object persisted in the repository.
  @override
  Future<Message> sendTextMessage(
    String text, {
    List<Attachment>? attachments,
    List<String>? mentionUserIds,
  }) async {
    final methodName = 'sendTextMessage';
    logger.info('Started sending group text message', name: methodName);

    final matrixRoomId = group.matrixRoomId;
    if (matrixRoomId == null || matrixRoomId.trim().isEmpty) {
      throw StateError(
        'Group does not have a Matrix room ID; cannot send group messages over Matrix.',
      );
    }

    // Upload + send Matrix events for attachments (no fallback).
    List<Attachment>? processedAttachments = attachments;
    if (attachments != null && attachments.isNotEmpty) {
      final updated = <Attachment>[];

      for (final attachment in attachments) {
        if (attachment.hasLink || attachment.data?.base64 != null) {
          final uploaded = await coreSDK.sendGroupAttachment(
            roomId: matrixRoomId,
            attachment: attachment,
          );
          updated.add(uploaded);
        } else {
          updated.add(attachment);
        }
      }

      processedAttachments = updated;

      logger.info(
        'Processed ${processedAttachments.length} attachments for group message',
        name: methodName,
      );
    }

    // IMPORTANT:
    // Group messages are sent over Matrix. Matrix reactions (`m.reaction`) link
    // to the *Matrix eventId* of the target message. The base implementation
    // persists outbound messages using the DIDComm message ID (UUID), which
    // causes cross-device reactions to never match on the sender device.
    // Persist with the Matrix eventId so reactions sync correctly.

    final channel = await getChannel();
    channel.increaseSeqNo();

    final eventId = await coreSDK.sendGroupMessageOverMatrix(
      roomId: matrixRoomId,
      message: text,
      senderDid: did,
      recipientDid: otherPartyDid,
      notify: true,
      mentionUserIds: mentionUserIds,
    );
    final now = DateTime.now().toUtc();
    final createdChatItem = await chatRepository.createMessage(
      Message(
        chatId: chatId,
        messageId: eventId,
        senderDid: did,
        value: text,
        isFromMe: true,
        dateCreated: now,
        status: ChatItemStatus.sent,
        attachments: processedAttachments ?? const <Attachment>[],
        mentionedUserIds: mentionUserIds ?? const <String>[],
      ),
    );

    await coreSDK.updateChannel(channel);
    chatStream.pushData(StreamData(chatItem: createdChatItem));

    logger.info('Completed sending group text message', name: methodName);
    return createdChatItem as Message;
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
  Future<bool> _handleMessage(PlainTextMessage message) async {
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
                eventMessage.data['memberDid'] == message.body?['from_did']),
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
      return true;
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

      return true;
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
      return true;
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
      return true;
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
      return true;
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
      return true;
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
      final messageHandledInternal = await _handleMessage(
        message.plainTextMessage,
      );

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
      if (!await _handleMessage(data.plainTextMessage)) {
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
