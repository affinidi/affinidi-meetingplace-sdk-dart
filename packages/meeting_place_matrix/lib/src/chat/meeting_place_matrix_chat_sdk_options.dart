import 'package:meeting_place_chat/meeting_place_chat.dart';

/// [MeetingPlaceChatSDKOptions] for a Matrix-backed chat, currently
/// forwarding every option to the base type without adding Matrix-specific
/// fields.
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
