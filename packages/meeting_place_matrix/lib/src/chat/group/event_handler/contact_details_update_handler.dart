import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import '../../../matrix_media_reference.dart';

import '../../../transport/matrix/outgoing/contact_details_update_sender.dart';

class ContactDetailsUpdateHandler implements ChatEventHandler {
  ContactDetailsUpdateHandler({
    required BaseChatSDK chatSDK,
    required ChatStream streamManager,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
    required Future<Channel> Function() getChannel,
  }) : _chatSDK = chatSDK,
       _streamManager = streamManager,
       _getGroup = getGroup,
       _setGroup = setGroup,
       _getChannel = getChannel;

  final BaseChatSDK _chatSDK;
  final ChatStream _streamManager;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;
  final Future<Channel> Function() _getChannel;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final senderDid = event.senderDid;
    if (senderDid == null) return;

    final profileDetails = await _resolveProfileDetails(event.content);
    if (profileDetails == null) return;

    final updatedGroup = await _handleContent(
      group: _getGroup(),
      memberDid: senderDid,
      profileDetails: profileDetails,
    );
    _setGroup(updatedGroup);
  }

  Future<Map<String, dynamic>?> _resolveProfileDetails(
    Map<String, dynamic> content,
  ) async {
    final eventId =
        content[ContactDetailsUpdateSender.contactCardEventIdKey] as String?;
    if (eventId != null) {
      try {
        final channel = await _getChannel();
        final bytes = await _chatSDK.coreSDK.downloadMedia(
          channel,
          MatrixEventMediaReference(eventId),
        );
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return content['profileDetails'] as Map<String, dynamic>?;
  }

  Future<Group> _handleContent({
    required Group group,
    required String memberDid,
    required Map<String, dynamic> profileDetails,
  }) async {
    final member = group.members.firstWhereOrNull((m) => m.did == memberDid);
    if (member == null) return group;

    member.contactCard = ContactCard.fromJson(profileDetails);

    await _chatSDK.coreSDK.updateGroup(group);
    _streamManager.pushData(
      StreamData(
        event: ChatContactDetailsUpdateEvent(
          senderDid: memberDid,
          contactCard: ContactCard.fromJson(profileDetails),
        ),
      ),
    );

    return group;
  }
}
