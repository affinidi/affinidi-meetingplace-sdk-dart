import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../outgoing/profile_request_room_event.dart';

class ProfileHashHandler {
  ProfileHashHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream chatStream,
    required String did,
    required String otherPartyDid,
  }) : _coreSDK = coreSDK,
       _chatStream = chatStream,
       _did = did,
       _otherPartyDid = otherPartyDid;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _chatStream;
  final String _did;
  final String _otherPartyDid;

  Future<void> handle(MatrixRoomEvent event) async {
    final incomingHash = event.content['profile_hash'] as String?;
    if (incomingHash == null) return;

    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyDid,
    );
    if (channel == null) return;

    final storedHash = channel.otherPartyContactCard?.profileHash;
    if (storedHash != incomingHash) {
      await _coreSDK.sendMessage(
        ProfileRequestRoomEvent(senderDid: _did, profileHash: incomingHash),
      );
    }

    _chatStream.pushData(
      StreamData(
        event: ChatProfileHashEvent(
          senderDid: event.senderDid ?? _otherPartyDid,
          profileHash: incomingHash,
        ),
      ),
    );
  }
}
