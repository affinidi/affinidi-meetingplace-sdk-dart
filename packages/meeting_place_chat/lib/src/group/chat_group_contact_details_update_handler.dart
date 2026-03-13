import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol/protocol.dart' as protocol;
import '../sdk/base_chat_sdk.dart';
import '../service/chat_stream.dart';

class ChatGroupContactDetailsUpdateHandler {
  ChatGroupContactDetailsUpdateHandler({
    required BaseChatSDK chatSDK,
    required ChatStream streamManager,
  }) : _chatSDK = chatSDK,
       _streamManager = streamManager;

  final BaseChatSDK _chatSDK;
  final ChatStream _streamManager;

  Future<Group> handle({
    required Group group,
    required PlainTextMessage message,
  }) async {
    final contactDetailsUpdate =
        protocol.ChatContactDetailsUpdate.fromPlainTextMessage(message);

    final member = group.members.firstWhere(
      (member) => member.did == contactDetailsUpdate.from,
      orElse: () => throw Exception('Group member not found'),
    );

    member.contactCard = ContactCard.fromJson(
      contactDetailsUpdate.profileDetails,
    );
    await _chatSDK.coreSDK.updateGroup(group);
    _streamManager.pushData(StreamData(plainTextMessage: message));

    unawaited(
      _chatSDK.sendPlainTextMessage(
        protocol.ChatGroupDetailsUpdate.fromGroup(
          group,
          senderDid: _chatSDK.did,
        ).toPlainTextMessage(),
        senderDid: _chatSDK.did,
        recipientDid: _chatSDK.otherPartyDid,
        mediatorDid: _chatSDK.mediatorDid,
      ),
    );

    return group;
  }
}
