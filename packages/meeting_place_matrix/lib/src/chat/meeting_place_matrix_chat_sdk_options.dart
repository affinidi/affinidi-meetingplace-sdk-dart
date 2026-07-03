import 'package:meeting_place_chat/meeting_place_chat.dart';

class MeetingPlaceMatrixChatSdkOptions extends MeetingPlaceChatSDKOptions {
  MeetingPlaceMatrixChatSdkOptions({
    super.chatPresenceSendInterval,
    super.chatPresenceExpiry,
    super.chatActivityExpiry,
    super.deleteMessageWindow,
    super.requiresAcknowledgement,
    super.memberJoinedIndicator,
  });
}
