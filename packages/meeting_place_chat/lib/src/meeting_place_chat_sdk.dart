import 'package:meeting_place_core/meeting_place_core.dart';

import '../meeting_place_chat.dart';

///  [MeetingPlaceChatSDK] is built on top of the core Meeting Place SDK.
///
/// It utilises:
/// - **Decentralised Identifiers (DID)** for a globally unique
///   identifierfor secure interactions.
/// - **DIDComm Messaging v2.1 protocol** for a secure, private,
///   and trusted communications across systems.
///
///  This class wraps either [GroupChatSDK] or [IndividualChatSDK]
///  depending on the channel type, and delegates all SDK calls
///  to the underlying implementation.
class MeetingPlaceChatSDK implements ChatSDK {
  /// Creates a new [MeetingPlaceChatSDK] instance with the given [ChatSDK]
  /// implementation.
  MeetingPlaceChatSDK({required ChatSDK sdk}) : _sdk = sdk;

  /// A constructor that initializes a [MeetingPlaceChatSDK] from a [Channel].
  ///
  /// **Parameters:**
  /// - [channel]: The [Channel] entity representing the chat.
  /// - [coreSDK]: Instance of [MeetingPlaceCoreSDK] to retrieve group
  ///   information if needed.
  /// - [chatRepository]: The [ChatRepository] used for persisting messages.
  /// - [options]: Configuration options for the chat.
  /// - [card]: Optional [ContactCard] representing the user profile.
  /// - [logger]: Optional logger implementation for custom logging behavior.
  ///   If not provided, uses DefaultChatSdkLogger.
  ///
  /// **Returns:**
  /// - A [MeetingPlaceChatSDK] that wraps either a [GroupChatSDK] (if
  ///   `channel.type` is `group`)
  ///   or an [IndividualChatSDK].
  static Future<MeetingPlaceChatSDK> initialiseFromChannel(
    Channel channel, {
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatSDKOptions options,
    ContactCard? card,
    MeetingPlaceChatSDKLogger? logger,
  }) async {
    if (channel.type == ChannelType.group) {
      final group =
          await coreSDK.getGroupByOfferLink(channel.offerLink) ??
          (throw Exception('Group not found'));

      return MeetingPlaceChatSDK(
        sdk: GroupChatSDK(
          coreSDK: coreSDK,
          group: group,
          did: channel.permanentChannelDid!,
          otherPartyDid: channel.otherPartyPermanentChannelDid!,
          mediatorDid: channel.mediatorDid,
          roomId: channel.matrixRoomId!,
          chatRepository: chatRepository,
          options: options,
          card: card,
          logger: logger,
        ),
      );
    } else {
      return MeetingPlaceChatSDK(
        sdk: IndividualChatSDK(
          coreSDK: coreSDK,
          did: channel.permanentChannelDid!,
          otherPartyDid: channel.otherPartyPermanentChannelDid!,
          mediatorDid: channel.mediatorDid,
          roomId: channel.matrixRoomId!,
          chatRepository: chatRepository,
          options: options,
          card: card,
          logger: logger,
        ),
      );
    }
  }

  final ChatSDK _sdk;

  /// Retrieves the list of existing messages in the channel.
  ///
  /// **Returns:**
  /// - A [List] of [ChatItem] objects.
  @override
  Future<List<ChatItem>> get messages {
    return _sdk.messages;
  }

  @override
  Future<ChatStream?> get chatStreamSubscription => _sdk.chatStreamSubscription;

  /// Starts a new chat session.
  ///
  /// **Returns:**
  /// - A [Chat] instance representing the started session.
  @override
  Future<Chat> startChatSession() {
    return _sdk.startChatSession();
  }

  /// Ends the active chat session.
  @override
  void endChatSession() async {
    return _sdk.endChatSession();
  }

  /// Retrieves a single message by ID.
  ///
  /// **Parameters:**
  /// - [messageId]: The unique identifier of the message.
  ///
  /// **Returns:**
  /// - A [ChatItem] if found, or `null` otherwise.
  @override
  Future<ChatItem?> getMessageById(String messageId) {
    return _sdk.getMessageById(messageId);
  }

  /// Sends updated chat contact details to the channel.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] containing updated details.
  @override
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) {
    return _sdk.sendChatContactDetailsUpdate(message);
  }

  /// Sends a plain text message (optionally with attachments).
  ///
  /// **Parameters:**
  /// - [text]: The message content.
  /// - [attachments]: An optional list of [ChatAttachment]s.
  ///
  /// **Returns:**
  /// - The sent [Message].
  @override
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment>? attachments,
  }) {
    return _sdk.sendTextMessage(text, attachments: attachments);
  }

  /// Reacts to a given message.
  ///
  /// **Parameters:**
  /// - [message]: The [Message] to react to.
  /// - [reaction]: The reaction string (e.g., emoji).
  @override
  Future<void> reactOnMessage(Message message, {required String reaction}) {
    return _sdk.reactOnMessage(message, reaction: reaction);
  }

  /// Sends a "chat activity" signal (e.g., typing indicator).
  @override
  Future<void> sendChatActivity() => _sdk.sendChatActivity();

  /// Sends a special chat effect.
  ///
  /// **Parameters:**
  /// - [effect]: The [Effect] to send.
  @override
  Future<void> sendEffect(Effect effect) => _sdk.sendEffect(effect);

  /// Approves an incoming connection request.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] representing the request.
  @override
  Future<void> approveConnectionRequest(ConciergeMessage message) =>
      _sdk.approveConnectionRequest(message);

  /// Rejects an incoming connection request.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] representing the request.
  @override
  Future<void> rejectConnectionRequest(ConciergeMessage message) =>
      _sdk.rejectConnectionRequest(message);

  /// Rejects an incoming chat contact details update.
  ///
  /// **Parameters:**
  /// - [message]: The [ConciergeMessage] representing the update request.
  @override
  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message) =>
      _sdk.rejectChatContactDetailsUpdate(message);

  /// Starts periodic chat presence updates to indicate the user is active in
  /// the chat.
  @override
  Future<void> startChatPresenceUpdates() => _sdk.startChatPresenceUpdates();

  /// Dispatches an arbitrary Matrix room event into the chat's room.
  ///
  /// Only supported for group chats. Throws [UnsupportedError] when the
  /// wrapped SDK is not a [GroupChatSDK].
  Future<void> sendRoomEvent(CustomRoomEvent event) {
    final sdk = _sdk;
    if (sdk is GroupChatSDK) return sdk.sendRoomEvent(event);
    throw UnsupportedError('sendRoomEvent is only supported for group chats');
  }
}
