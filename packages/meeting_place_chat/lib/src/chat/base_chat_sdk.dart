import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../logger/logger_formatter.dart';
import '../logger/top_and_tail_extension.dart';

/// [BaseChatSDK] is an abstract base class that provides functionality
/// for Chat App implementations.
///
/// It is built on top of the Meeting Place Core SDK and leverages:
/// - **Decentralised Identifiers (DIDs)** for a globally unique
///   identifierfor secure interactions.
/// - **DIDComm Messaging v2.1 protocol** for a secure, private,
///   and trusted communications across systems.
///
/// Responsibilities:
/// - Manage chat lifecycle (start, resume, end).
/// - Persist messages via [ChatRepository].
/// - Dispatch live events through a [ChatStream].
///
/// All wire-level operations (sending text/reactions/edits/deliveries/presence/
/// activity/contact-details updates, subscribing to incoming events, fetching
/// history) are abstract and implemented by transport-flavoured subclasses.
abstract class BaseChatSDK {
  BaseChatSDK({
    required this.coreSDK,
    required this.did,
    required this.otherPartyDid,
    required this.mediatorDid,
    required this.chatRepository,
    required this.options,
    this.card,
    MeetingPlaceCoreSDKLogger? logger,
  }) : chatStream = ChatStream(),
       _logger = LoggerFormatter(className: _className, baseLogger: logger);

  static const String _className = 'BaseChatSDK';
  static const String _logkey = 'BaseChatSDK';

  final MeetingPlaceCoreSDK coreSDK;
  final String did;
  final String otherPartyDid;
  final String mediatorDid;
  final ChatRepository chatRepository;
  final MeetingPlaceChatSDKOptions options;
  final ContactCard? card;
  final MeetingPlaceChatSDKLogger _logger;

  /// The freshest contact card available for the signed-in identity.
  ///
  /// Retained chat sessions may outlive profile edits, so profile-update
  /// decisions should read this getter instead of the construction-time
  /// snapshot in [card].
  ContactCard? get currentContactCard =>
      options.resolveCurrentContactCard?.call() ?? card;

  MeetingPlaceChatSDKLogger get logger => _logger;

  ChatStream chatStream;

  /// Future that completes when the transport subscription is ready.
  /// Subclasses set this from [startChatSession].
  @protected
  Future<void>? transportSubscriptionFuture;

  /// Hook for subclasses to block sends when the chat is in an invalid state
  /// (e.g. a deleted group). Default: no-op.
  @protected
  void assertCanSend() {}

  /// Unique chat ID derived from [did] and [otherPartyDid].
  String get chatId => Chat.deriveId(did: did, otherPartyDid: otherPartyDid);

  /// Maximum age at which the original sender can still delete one of their
  /// own messages for everyone. Mirrors
  /// [MeetingPlaceChatSDKOptions.deleteMessageWindow] so UI layers can gate
  /// the delete-for-everyone affordance without reaching into [options].
  Duration get deleteMessageWindow => options.deleteMessageWindow;

  /// Starts a chat session.
  ///
  /// Transport-specific subclasses are responsible for subscribing to the
  /// incoming stream and replaying any history. They must also assign
  /// [transportSubscriptionFuture] so callers can await transport readiness.
  Future<Chat> startChatSession();

  /// Stream of live chat events ([StreamData]) for this session.
  ///
  /// Resolves as soon as [startChatSession] has been called — the underlying
  /// [ChatStream] buffers any events pushed before a listener attaches and
  /// flushes them on first subscription, so callers do not need to wait for
  /// the transport subscription to be ready.
  ///
  /// **Returns:**
  /// - A [ChatStream] or `null` if the chat session has not yet started
  ///   or resumed.
  Future<ChatStream?> get chatStreamSubscription async {
    if (transportSubscriptionFuture == null) return null;
    await transportSubscriptionFuture;
    return chatStream;
  }

  /// Retrieves all messages for this chat. Implementation depends on the
  /// underlying transport.
  Future<List<ChatItem>> get messages;

  /// Retrieves a single message by ID.
  Future<ChatItem?> getMessageById(String messageId) {
    _logger.info('Retrieving message by ID: $messageId', name: _logkey);
    return chatRepository.getMessage(chatId: chatId, messageId: messageId);
  }

  /// Stream of live chat events ([StreamData]) for this session.
  Stream<StreamData> get stream => chatStream.stream;

  /// Sends a plain text message with optional [attachments].
  ///
  /// Text and media travel together: each attachment is sent as a single
  /// transport event carrying [text] as its caption. When multiple
  /// attachments are supplied, only the first event carries [text]; the
  /// rest are sent without a caption. Returns the single persisted
  /// [Message] carrying all attachments.
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment> attachments = const [],
  });

  /// Downloads and decrypts the media bytes referenced by
  /// [attachment]. Resolves the wire-level reference
  /// ([ChatAttachment.transportId]) via the underlying transport, so SDK
  /// consumers never see encryption keys or transport URIs. For DIDComm
  /// attachments the bytes are decoded inline from [ChatAttachmentData].
  Future<Uint8List> downloadMedia(ChatAttachment attachment);

  /// Starts periodic chat presence updates.
  Future<void> startChatPresenceUpdates() async {}

  /// Sends a chat presence signal to the other party.
  Future<void> sendChatPresence();

  /// Triggers a profile update proposal if the local contact card differs from
  /// the persisted channel card.
  Future<void> proposeProfileUpdate();

  /// Sends a delivery receipt for [messageId].
  Future<void> sendChatDeliveredMessage(String messageId);

  /// Sends updated contact details from the current contact card.
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message);

  /// Rejects a contact details update and marks message as confirmed.
  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message) async {
    message.status = ChatItemStatus.confirmed;
    await chatRepository.updateMesssage(message);

    _logger.info('Chat contact details update rejected', name: _logkey);
    chatStream.pushData(StreamData(chatItem: message));
  }

  /// Reacts (or unreacts) to a chat message with an emoji or symbol.
  Future<void> reactOnMessage(Message message, {required String reaction});

  /// Edits a previously sent text message.
  Future<void> editTextMessage(Message message, String newText);

  /// Deletes a chat message.
  ///
  /// When [localOnly] is `false` (the default), broadcasts a transport-level
  /// redaction so all participants drop the message. Only the original
  /// sender may perform this, and only within
  /// [MeetingPlaceChatSDKOptions.deleteMessageWindow].
  ///
  /// When [localOnly] is `true`, marks the message as hidden for the local
  /// user only — no wire traffic, no time limit, applies to any message
  /// regardless of author.
  Future<void> deleteMessage(Message message, {bool localOnly = false});

  /// Sends a chat effect (visual/animated signal).
  Future<void> sendEffect(Effect effect);

  /// Sends a chat activity message (e.g., typing indicator).
  Future<void> sendChatActivity();

  /// Ends the chat session, disposing of the stream manager.
  Future<void> end() async {
    transportSubscriptionFuture = null;
    chatStream.dispose();
  }

  Future<Channel> getChannel() async {
    return await coreSDK.getChannelByOtherPartyPermanentDid(otherPartyDid) ??
        (throw Exception(
          'Channel with other party DID ${otherPartyDid.topAndTail()} not '
          'found',
        ));
  }

  /// Creates a local chat [Message] with the given attachments.
  ///
  /// [senderDid] must be the DID of the party who sent the credential —
  /// pass [Channel.permanentChannelDid] for an outgoing exchange, or
  /// [Channel.otherPartyPermanentChannelDid] for an incoming one.
  Future<void> createAttachmentMessage({
    required List<ChatAttachment> attachments,
    required String senderDid,
  }) async {
    if (senderDid != did && senderDid != otherPartyDid) {
      throw Exception(
        'senderDid $senderDid is not a participant of this chat '
        '(did=$did, otherPartyDid=$otherPartyDid).',
      );
    }
    final chatMessage = Message(
      chatId: chatId,
      messageId: const Uuid().v4(),
      senderDid: senderDid,
      isFromMe: senderDid == did,
      dateCreated: DateTime.now().toUtc(),
      status: ChatItemStatus.confirmed,
      value: '',
      attachments: attachments,
    );
    await chatRepository.createMessage(chatMessage);
    chatStream.pushData(StreamData(chatItem: chatMessage));
  }
}
