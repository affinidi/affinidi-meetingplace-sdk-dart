import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import '../../core/chat_stream/chat_stream.dart';
import '../../core/chat_stream/stream_data.dart';
import '../factory/pending_approval_concierge_factory.dart';

class ChatGroupInvitationAcceptHandler {
  ChatGroupInvitationAcceptHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required MeetingPlaceChatSDKLogger logger,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _streamManager = streamManager,
       _logger = logger;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final MeetingPlaceChatSDKLogger _logger;

  /// Handles an [InvitationGroupAccept] event.
  ///
  /// Returns the refreshed [Group] if the event was handled, or `null` if the
  /// event type or group ID did not match.
  Future<Group?> handle({
    required ControlPlaneStreamEvent event,
    required Group group,
    required Chat chat,
  }) async {
    if (group.did != event.channel.otherPartyPermanentChannelDid) return null;
    final updatedGroup = (await _coreSDK.getGroupById(group.id))!;

    final conciergeMessages = await PendingApprovalConciergeFactory(
      chatRepository: _chatRepository,
      logger: _logger,
    ).create(group: updatedGroup, chat: chat);

    for (final message in conciergeMessages) {
      _streamManager.pushData(StreamData(chatItem: message));
    }

    return updatedGroup;
  }
}
