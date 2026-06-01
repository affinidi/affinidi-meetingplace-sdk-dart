import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

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
/// history) are abstract and implemented by transport-flavoured subclasses
/// such as `GroupMatrixChatSDK`, `IndividualMatrixChatSDK`, or
/// `IndividualDidcommChatSDK`.
abstract class BaseChatSDK {
  BaseChatSDK({
    required this.coreSDK,
    required this.did,
    required this.otherPartyDid,
    required this.mediatorDid,
    required this.chatRepository,
    required this.options,
    this.card,
    MeetingPlaceChatSDKLogger? logger,
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

  /// Starts a chat session.
  ///
  /// Transport-specific subclasses are responsible for subscribing to the
  /// incoming stream and replaying any history. They must also assign
  /// [transportSubscriptionFuture] so [chatStreamSubscription] can await it.
  Future<Chat> startChatSession();

  /// Waits until the transport subscription is ready. Stream of live
  /// chat events ([StreamData]) for this session.
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
  /// underlying transport — Matrix replays the timeline, DIDComm returns the
  /// locally persisted set.
  Future<List<ChatItem>> get messages;

  /// Retrieves a single message by ID.
  Future<ChatItem?> getMessageById(String messageId) {
    _logger.info('Retrieving message by ID: $messageId', name: _logkey);
    return chatRepository.getMessage(chatId: chatId, messageId: messageId);
  }

  /// Stream of live chat events ([StreamData]) for this session.
  Stream<StreamData> get stream => chatStream.stream;

  /// Sends a plain text message with optional attachments.
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment>? attachments,
  });

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

  /// Sends a chat effect (visual/animated signal).
  Future<void> sendEffect(Effect effect);

  /// Sends a chat activity message (e.g., typing indicator).
  Future<void> sendChatActivity();

  /// Ends the chat session, disposing of the stream manager.
  Future<void> end() async {
    transportSubscriptionFuture = null;
    chatStream.dispose();
  }

  @internal
  Future<Channel> getChannel() async {
    return await coreSDK.getChannelByOtherPartyPermanentDid(otherPartyDid) ??
        (throw Exception(
          'Channel with other party DID ${otherPartyDid.topAndTail()} not '
          'found',
        ));
  }
}
