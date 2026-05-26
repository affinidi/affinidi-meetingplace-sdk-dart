import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';

class MemberDeregisteredHandler implements ChatEventHandler {
  MemberDeregisteredHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required String chatId,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _streamManager = streamManager,
       _chatId = chatId,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final String _chatId;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final senderDid = event.senderDid;
    if (senderDid == null) return;

    final group = _getGroup();
    final member = group.members.firstWhere(
      (member) => member.did == senderDid,
      orElse: () => throw Exception('Member not found in group'),
    );

    if (member.status == GroupMemberStatus.deleted) return;

    member.status = GroupMemberStatus.deleted;
    await _coreSDK.updateGroup(group);
    _setGroup(group);

    final chatItem = await _chatRepository.createMessage(
      EventMessage.groupMemberLeft(
        chatId: _chatId,
        groupDid: group.did,
        memberDid: senderDid,
        memberCard: member.contactCard.toJson(),
      ),
    );

    _streamManager.pushData(
      StreamData(event: event.toChatEvent(), chatItem: chatItem),
    );
  }
}
