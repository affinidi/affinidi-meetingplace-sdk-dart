import 'package:meeting_place_core/meeting_place_core.dart';

import '../service/chat_stream.dart';

class ChatGroupContactDetailsUpdateHandler {
  ChatGroupContactDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatStream streamManager,
  }) : _coreSDK = coreSDK,
       _streamManager = streamManager;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatStream _streamManager;

  Future<Group> handle({
    required Group group,
    required PlainTextMessage message,
  }) async {
    final member = group.members.firstWhere(
      (member) => member.did == message.from!,
      orElse: () => throw Exception('Group member not found'),
    );

    member.contactCard = ContactCard.fromJson(message.body!);
    await _coreSDK.updateGroup(group);
    _streamManager.pushData(StreamData(plainTextMessage: message));
    return group;
  }
}
