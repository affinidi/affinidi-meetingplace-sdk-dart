import 'dart:async';

import '../../../meeting_place_chat.dart';
import '../../constants.dart';
import '../../logger/default_meeting_place_chat_sdk_logger.dart';
import '../../transport/matrix/outgoing/profile_hash_room_event.dart';
import '../matrix_chat_sdk.dart';

/// Matrix-backed implementation of [MeetingPlaceChatSDK] for one-to-one chats.
///
/// Built on top of [MatrixChatSDK] for the Matrix transport. Owns the
/// per-individual presence loop and the profile-hash propose flow.
class IndividualMatrixChatSDK extends MatrixChatSDK
    implements MeetingPlaceChatSDK {
  IndividualMatrixChatSDK({
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

  static const String _className = 'IndividualMatrixChatSDK';
  static const String _logkey = 'IndividualMatrixChatSDK';

  bool _isSendingChatPresence = false;

  @override
  Future<Chat> startChatSession() async {
    final chat = await super.startChatSession();
    unawaited(startChatPresenceUpdates());
    return chat;
  }

  @override
  Future<void> endChatSession() async {
    await super.end();
    stopChatPresenceInterval();
  }

  @override
  Future<void> approveConnectionRequest(ConciergeMessage message) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectConnectionRequest(ConciergeMessage message) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMember(String memberDid) {
    throw UnimplementedError();
  }

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
  Future<void> proposeProfileUpdate() async {
    if (card == null) {
      logger.info(
        'ContactCard is null, skipping profile hash update',
        name: _logkey,
      );
      return;
    }

    final channel = await getChannel();
    if (channel.contactCard != null && !card!.equals(channel.contactCard!)) {
      await coreSDK.sendMessage(
        ProfileHashRoomEvent(senderDid: did, profileHash: card!.profileHash),
      );

      channel.contactCard = card;
      await coreSDK.updateChannel(channel);
    }

    logger.info('Completed sending profile hash', name: _logkey);
  }
}
