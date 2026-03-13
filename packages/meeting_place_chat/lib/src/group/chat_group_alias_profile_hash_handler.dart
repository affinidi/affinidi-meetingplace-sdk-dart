import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol/protocol.dart' as protocol;
import '../sdk/base_chat_sdk.dart';
import '../service/chat_stream.dart';

class ChatGroupAliasProfileHashHandler {
  ChatGroupAliasProfileHashHandler({
    required BaseChatSDK chatSDK,
    required ChatStream streamManager,
  }) : _chatSDK = chatSDK,
       _streamManager = streamManager;

  final BaseChatSDK _chatSDK;
  final ChatStream _streamManager;

  Future<void> handle({
    required Group group,
    required PlainTextMessage message,
  }) async {
    final profileHashMessage =
        protocol.ChatAliasProfileHash.fromPlainTextMessage(message);
    final profileHash = profileHashMessage.body.profileHash;

    final member = group.members.firstWhere(
      (member) => member.did == profileHashMessage.from,
      orElse: () =>
          throw Exception('Group member ${profileHashMessage.from} not found'),
    );

    if (member.contactCard.profileHash != profileHash) {
      await _chatSDK.sendDirectMessage(
        protocol.ChatAliasProfileRequest.create(
          from: _chatSDK.did,
          to: [profileHashMessage.from],
          profileHash: profileHash,
        ).toPlainTextMessage(),
        recipientDid: profileHashMessage.from,
      );
    }

    _streamManager.pushData(StreamData(plainTextMessage: message));
  }
}
