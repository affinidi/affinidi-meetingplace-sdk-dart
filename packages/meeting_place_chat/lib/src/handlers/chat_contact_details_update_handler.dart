import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';

class ChatContactDetailsUpdateHandler {
  ChatContactDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream streamManager,
  }) : _coreSDK = coreSDK,
       _streamManager = streamManager;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _streamManager;

  Future<void> handle({
    required PlainTextMessage message,
    required Channel channel,
  }) async {
    final contactDetailsUpdate = ChatContactDetailsUpdate.fromPlainTextMessage(
      message,
    );

    channel.otherPartyContactCard = ContactCard.fromJson(
      contactDetailsUpdate.profileDetails,
    );
    await _coreSDK.updateChannel(channel);
    _streamManager.pushData(StreamData(plainTextMessage: message));
  }
}
