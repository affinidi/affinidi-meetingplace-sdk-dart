import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import '../../transport/matrix/outgoing/contact_details_update_sender.dart';

class IndividualContactDetailsUpdateHandler {
  IndividualContactDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream chatStream,
    required String otherPartyDid,
    required Future<Channel> Function() getChannel,
    required MeetingPlaceChatSDKLogger logger,
  }) : _coreSDK = coreSDK,
       _chatStream = chatStream,
       _otherPartyDid = otherPartyDid,
       _getChannel = getChannel,
       _logger = logger;

  static const _logKey = 'IndividualContactDetailsUpdateHandler';

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _chatStream;
  final String _otherPartyDid;
  final Future<Channel> Function() _getChannel;
  final MeetingPlaceChatSDKLogger _logger;

  Future<void> handle(MatrixRoomEvent event) async {
    final profileDetails = await _resolveProfileDetails(event.content);
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

  Future<Map<String, dynamic>?> _resolveProfileDetails(
    Map<String, dynamic> content,
  ) async {
    final eventId = content[ContactDetailsUpdateSender.contactCardEventIdKey];
    if (eventId != null && eventId is String) {
      try {
        final channel = await _getChannel();
        final bytes = await _coreSDK.downloadMedia(
          channel,
          MatrixEventMediaReference(eventId),
        );
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      } catch (e, st) {
        _logger.error(
          'Failed to download contact card for individual chat',
          name: _logKey,
          error: e,
          stackTrace: st,
        );
        return null;
      }
    }
    return content['profileDetails'] as Map<String, dynamic>?;
  }
}
