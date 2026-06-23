import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import '../../transport/matrix/outgoing/contact_details_update_sender.dart';

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
    final eventId =
        event.content[ContactDetailsUpdateSender.contactCardEventIdKey]
            as String?;

    if (profileDetails == null && eventId == null) return;

    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyDid,
    );
    if (channel == null) return;

    ContactCard updatedCard;

    if (profileDetails != null) {
      updatedCard = ContactCard.fromJson(profileDetails);
    } else {
      try {
        final bytes = await _coreSDK.downloadMedia(
          channel,
          MatrixEventMediaReference(eventId!),
        );
        updatedCard = ContactCard.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        );
      } catch (_) {
        return;
      }
    }

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
