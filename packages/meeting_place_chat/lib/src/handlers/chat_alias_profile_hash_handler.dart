import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';
import '../sdk/base_chat_sdk.dart';

class ChatAliasProfileHashHandler {
  ChatAliasProfileHashHandler({
    required BaseChatSDK chatSDK,
    required ChatStream streamManager,
  }) : _chatSDK = chatSDK,
       _streamManager = streamManager;

  final BaseChatSDK _chatSDK;
  final ChatStream _streamManager;

  Future<void> handle({
    required PlainTextMessage message,
    required Channel channel,
  }) async {
    final profileHashMessage =
        ChatAliasProfileHash.fromPlainTextMessage(message);
    final profileHash = profileHashMessage.body.profileHash;

    if (channel.otherPartyContactCard != null &&
        channel.otherPartyContactCard!.profileHash == profileHash) {
      _streamManager.pushData(StreamData(plainTextMessage: message));
      return;
    }

    await _chatSDK.sendMessage(
      ChatAliasProfileRequest.create(
        from: _chatSDK.did,
        to: [_chatSDK.otherPartyDid],
        profileHash: profileHash,
      ).toPlainTextMessage(),
    );

    _streamManager.pushData(StreamData(plainTextMessage: message));
  }
}
