import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import 'package:meeting_place_chat/meeting_place_chat.dart';

class PendingApprovalConciergeFactory {
  PendingApprovalConciergeFactory({
    required ChatRepository chatRepository,
    required MeetingPlaceChatSDKLogger logger,
  }) : _chatRepository = chatRepository,
       _logger = logger;

  static const _logkey = 'create';

  final ChatRepository _chatRepository;
  final MeetingPlaceChatSDKLogger _logger;

  Future<List<ChatItem>> create({
    required Group group,
    required Chat chat,
  }) async {
    _logger.info(
      'Looking up group members with pending approval status.',
      name: _logkey,
    );

    final pendingApprovals = group.getGroupMembersWaitingForApproval();
    final conciergeMessages = <ChatItem>[];

    for (final pendingApproval in pendingApprovals) {
      if (_hasConciergeMessage(chat.messages, pendingApproval.did)) continue;

      final conciergeMessage = _buildConciergeMessage(
        chatId: chat.id,
        group: group,
        pendingApproval: pendingApproval,
      );

      await _chatRepository.createMessage(conciergeMessage);
      chat.messages.add(conciergeMessage);
      conciergeMessages.add(conciergeMessage);
    }

    _logger.info(
      'Completed creating ${conciergeMessages.length} concierge messages',
      name: _logkey,
    );

    return conciergeMessages;
  }

  static ChatItem _buildConciergeMessage({
    required String chatId,
    required Group group,
    required GroupMember pendingApproval,
  }) => ConciergeMessage(
    chatId: chatId,
    messageId: const Uuid().v4(),
    senderDid: pendingApproval.did,
    isFromMe: false,
    dateCreated: DateTime.now().toUtc(),
    status: ChatItemStatus.userInput,
    conciergeType: ConciergeMessageType.permissionToJoinGroup,
    data: {
      'groupId': group.id,
      'contactCard': pendingApproval.contactCard.toJson(),
      'memberDid': pendingApproval.did,
      'adminDid': group.ownerDid,
      'offerLink': group.offerLink,
    },
  );

  static bool _hasConciergeMessage(List<ChatItem> messages, String memberDid) =>
      messages.any(
        (m) =>
            m is ConciergeMessage &&
            m.conciergeType == ConciergeMessageType.permissionToJoinGroup &&
            m.data['memberDid'] == memberDid,
      );
}
