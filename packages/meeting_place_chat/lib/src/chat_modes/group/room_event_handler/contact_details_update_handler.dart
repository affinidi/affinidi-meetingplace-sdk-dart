import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../events/chat_event.dart';
import '../../../events/chat_event_conversion.dart';
import '../../../stream/chat_stream.dart';
import '../../../events/stream_data.dart';
import '../../../transport/matrix/matrix_user_id_cache.dart';
import '../../base_chat_sdk.dart';
import '../../../transport/matrix/incoming/room_event_handler.dart';

class ContactDetailsUpdateHandler implements RoomEventHandler {
  ContactDetailsUpdateHandler({
    required BaseChatSDK chatSDK,
    required ChatStream streamManager,
    required MatrixUserIdCache didCache,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
  }) : _chatSDK = chatSDK,
       _streamManager = streamManager,
       _didCache = didCache,
       _getGroup = getGroup,
       _setGroup = setGroup;

  final BaseChatSDK _chatSDK;
  final ChatStream _streamManager;
  final MatrixUserIdCache _didCache;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = _didCache.resolve(event.userId);
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
