import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../matrix_room_event.dart';

class ProfileRequestHandler {
  ProfileRequestHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required String otherPartyDid,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _otherPartyDid = otherPartyDid;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final String _otherPartyDid;

  Future<void> handle(MatrixRoomEvent event) async {
    final profileHash = event.content['profile_hash'] as String?;
    if (profileHash == null) return;

    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyDid,
    );
    final replyTo = channel?.otherPartyContactCard?.did ?? event.senderDid;

    final existing = await _findPendingProfileUpdateConcierge();
    if (existing != null) {
      existing.data['profileHash'] = profileHash;
      existing.data['replyTo'] = replyTo;
      final updated = await _chatRepository.updateMesssage(existing);
      _chatStream.pushData(
        StreamData(
          event: ChatProfileRequestEvent(
            senderDid: event.senderDid ?? _otherPartyDid,
            profileHash: profileHash,
          ),
          chatItem: updated,
        ),
      );
      return;
    }

    final conciergeMessage = ConciergeMessage(
      chatId: _chatId,
      messageId: event.id,
      senderDid: event.senderDid ?? _otherPartyDid,
      isFromMe: false,
      dateCreated: event.timestamp,
      status: ChatItemStatus.userInput,
      conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      data: {'profileHash': profileHash, 'replyTo': replyTo},
    );

    final created = await _chatRepository.createMessage(conciergeMessage);
    _chatStream.pushData(
      StreamData(
        event: ChatProfileRequestEvent(
          senderDid: event.senderDid ?? _otherPartyDid,
          profileHash: profileHash,
        ),
        chatItem: created,
      ),
    );
  }

  /// Returns the outstanding profile-update concierge still awaiting the
  /// user's decision, so a repeated profile request collapses onto it instead
  /// of stacking a second prompt.
  Future<ConciergeMessage?> _findPendingProfileUpdateConcierge() async {
    final messages = await _chatRepository.listMessages(_chatId);
    for (final item in messages) {
      if (item is ConciergeMessage &&
          item.conciergeType ==
              ConciergeMessageType.permissionToUpdateProfile &&
          item.status == ChatItemStatus.userInput) {
        return item;
      }
    }
    return null;
  }
}
