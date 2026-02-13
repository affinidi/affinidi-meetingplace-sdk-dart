import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';
import '../constants/sdk_constants.dart';
import '../loggers/default_meeting_place_chat_sdk_logger.dart';
import 'base_chat_sdk.dart';
import 'chat.dart';

/// [IndividualChatSDK] is a specialized implementation of [ChatSDK] for handling
/// **one-to-one (individual) chat sessions** in the Meeting Place SDK.
///
/// Built on top of [BaseChatSDK], it leverages:
/// - **Decentralised Identifiers (DIDs)** for a globally unique
///   identifierfor secure interactions.
/// - **DIDComm Messaging v2.1 protocol** for a secure, private,
///   and trusted communications across systems.
///
/// Responsibilities include:
/// - Starting/resuming an individual chat.
/// - Sending direct messages, activities, and presence signals.
/// - Maintaining periodic presence updates while the chat is active.
class IndividualChatSDK extends BaseChatSDK implements ChatSDK {
  IndividualChatSDK({
    required super.coreSDK,
    required super.did,
    required super.otherPartyDid,
    required super.mediatorDid,
    required super.chatRepository,
    required super.options,
    super.card,
    MeetingPlaceChatSDKLogger? logger,
  }) : super(
         logger:
             logger ??
             DefaultMeetingPlaceChatSDKLogger(
               className: _className,
               sdkName: sdkName,
             ),
       );

  static const String _className = 'IndividualChatSDK';

  bool _sendChatPresence = true;

  /// Starts an individual chat session.
  ///
  /// Automatically begins sending **chat presence signals** at a configured
  /// interval to indicate that the user is active.
  ///
  /// **Returns:**
  /// - A [Chat] instance representing the started session.
  @override
  Future<Chat> startChatSession() async {
    final chat = await super.startChatSession();
    if (options.onChatSessionStart != null) {
      options.onChatSessionStart!(this);
    }

    unawaited(
      startChatPresenceInInterval(options.chatPresenceSendInterval.inSeconds),
    );
    return chat;
  }

  /// Ends the chat session and stops periodic chat presence updates.
  @override
  void endChatSession() {
    super.end();
    stopChatPresenceInterval();
  }

  /// Approves a pending connection request.
  ///
  /// ⚠️ Currently not implemented for individual chats.
  ///
  /// **Throws:**
  /// - [UnimplementedError] when called.
  @override
  Future<void> approveConnectionRequest(ConciergeMessage message) {
    throw UnimplementedError();
  }

  /// Rejects a pending connection request.
  ///
  /// ⚠️ Currently not implemented for individual chats.
  ///
  /// **Throws:**
  /// - [UnimplementedError] when called.
  @override
  Future<void> rejectConnectionRequest(ConciergeMessage message) {
    throw UnimplementedError();
  }

  /// Sends a direct plain text message to another party.
  ///
  /// **Parameters:**
  /// - [message]: The [PlainTextMessage] to send.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [recipientDid]: DID of the recipient of the message.
  /// - [mediatorDid]: DID of the mediator used for routing.
  /// - [notify]: Whether to notify via `"chat-activity"` channel
  /// (default: `false`).
  /// - [ephemeral]: Whether the message is ephemeral (default: `false`).
  /// - [forwardExpiryInSeconds]: Optional duration (in seconds) after which
  /// the forwarded message is considered expired.
  /// **Returns:**
  /// - A [Future] that completes when the message has been sent.
  @override
  Future<void> sendChatMessage(
    PlainTextMessage message, {
    required String senderDid,
    required String recipientDid,
    required String mediatorDid,
    bool notify = false,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) {
    return coreSDK.sendMessage(
      message,
      senderDid: senderDid,
      recipientDid: recipientDid,
      mediatorDid: mediatorDid,
      notifyChannelType: notify ? NotifyChannelType.chatActivity : null,
      ephemeral: ephemeral,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );
  }

  /// Starts periodically sending chat presence signals (e.g., "online").
  ///
  /// **Parameters:**
  /// - [intervalInSeconds]: Interval in seconds between presence updates.
  ///
  /// Runs continuously in a loop until [stopChatPresenceInterval] is called.
  Future<void> startChatPresenceInInterval(int intervalInSeconds) async {
    _sendChatPresence = true;
    while (_sendChatPresence) {
      try {
        await sendChatPresence();
        await Future<void>.delayed(Duration(seconds: intervalInSeconds));
      } catch (e) {
        logger.error('Error sending chat presence signal: $e');
        stopChatPresenceInterval();
      }
    }
  }

  /// Stops the periodic sending of chat presence signals.
  void stopChatPresenceInterval() {
    _sendChatPresence = false;
  }
}
