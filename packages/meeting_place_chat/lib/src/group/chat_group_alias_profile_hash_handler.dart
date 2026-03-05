import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol/protocol.dart' as protocol;
import '../service/chat_stream.dart';

class ChatGroupAliasProfileHashHandler {
  ChatGroupAliasProfileHashHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream streamManager,
  }) : _coreSDK = coreSDK,
       _streamManager = streamManager;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _streamManager;

  Future<void> handle({
    required Group group,
    required PlainTextMessage message,
    required String did,
    required String mediatorDid,
  }) async {
    final profileHash = message.body?['profile_hash'];
    if (profileHash != null && profileHash is String) {
      final member = group.members.firstWhere(
        (member) => member.did == message.from!,
        orElse: () => throw Exception(
          'Group member ${message.from} not found',
        ),
      );

      if (member.contactCard.profileHash != profileHash) {
        await _coreSDK.sendMessage(
          protocol.ChatAliasProfileRequest.create(
            from: did,
            to: [message.from!],
            profileHash: profileHash,
          ).toPlainTextMessage(),
          senderDid: did,
          recipientDid: message.from!,
          mediatorDid: mediatorDid,
        );
      }

      _streamManager.pushData(StreamData(plainTextMessage: message));
    }
  }
}
