import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';
import '../../base_chat_sdk.dart';

class ContactDetailsUpdateHandler implements ChatEventHandler {
  ContactDetailsUpdateHandler({
    required BaseChatSDK chatSDK,
    required ChatStream streamManager,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _chatSDK = chatSDK,
       _streamManager = streamManager,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final BaseChatSDK _chatSDK;
  final ChatStream _streamManager;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final senderDid = event.senderDid;
    if (senderDid == null) return;

    final profileDetails =
        event.content['profileDetails'] as Map<String, dynamic>?;
    if (profileDetails == null) return;

    final updated = await _handleContent(
      group: _getGroup(),
      memberDid: senderDid,
      profileDetails: profileDetails,
      chatEvent: event.toChatEvent(),
    );
    _setGroup(updated);
  }

  Future<Group> _handleContent({
    required Group group,
    required String memberDid,
    required Map<String, dynamic> profileDetails,
    required ChatEvent chatEvent,
  }) async {
    final member = group.members.firstWhereOrNull((m) => m.did == memberDid);
    if (member == null) return group;

    member.contactCard = ContactCard.fromJson(profileDetails);
    await _chatSDK.coreSDK.updateGroup(group);
    _streamManager.pushData(StreamData(event: chatEvent));

    return group;
  }
}
