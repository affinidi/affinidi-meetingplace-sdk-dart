import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';
import '../utils/chat_utils.dart';

class ChatAliasProfileHashHandler {
  ChatAliasProfileHashHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream streamManager,
  }) : _coreSDK = coreSDK,
       _streamManager = streamManager;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _streamManager;

  Future<void> handle({
    required PlainTextMessage message,
    required Channel channel,
    required String did,
    required String otherPartyDid,
    required String mediatorDid,
  }) async {
    final profileHash = message.body?['profile_hash'];
    if (profileHash == null || profileHash is! String) {
      return;
    }

    if (channel.otherPartyContactCard != null &&
        ChatUtils.contactHash(channel.otherPartyContactCard!) == profileHash) {
      _streamManager.pushData(StreamData(plainTextMessage: message));
      return;
    }

    await _coreSDK.sendMessage(
      ChatAliasProfileRequest.create(
        from: did,
        to: [otherPartyDid],
        profileHash: profileHash,
      ).toPlainTextMessage(),
      senderDid: did,
      recipientDid: otherPartyDid,
      mediatorDid: mediatorDid,
    );

    _streamManager.pushData(StreamData(plainTextMessage: message));
  }
}
