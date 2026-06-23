import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';

class IndividualContactDetailsUpdateHandler {
  IndividualContactDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream chatStream,
    required String otherPartyDid,
  }) : _coreSDK = coreSDK,
       _chatStream = chatStream,
       _otherPartyDid = otherPartyDid;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _chatStream;
  final String _otherPartyDid;

  Future<void> handle(MatrixRoomEvent event) async {
    final profileDetails =
        event.content['profileDetails'] as Map<String, dynamic>?;
    if (profileDetails == null) return;

    final updatedCard = ContactCard.fromJson(profileDetails);
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyDid,
    );
    if (channel == null) return;

    channel.otherPartyContactCard = updatedCard;
    await _coreSDK.updateChannel(channel);

    _chatStream.pushData(
      StreamData(
        event: ChatContactDetailsUpdateEvent(
          senderDid: event.senderDid ?? _otherPartyDid,
          contactCard: updatedCard,
        ),
      ),
    );
  }
}
