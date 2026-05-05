import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import 'chat_event.dart';

@internal
extension PlainTextMessageToChatEvent on PlainTextMessage {
  ChatEvent toChatEvent() => ChatEvent(
    type: type.toString(),
    senderDid: from,
    body: body,
    createdTime: createdTime,
  );
}
