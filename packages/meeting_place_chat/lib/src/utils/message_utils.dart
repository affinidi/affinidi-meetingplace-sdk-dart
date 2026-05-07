import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_chat.dart';

class MessageUtils {
  static bool isType(PlainTextMessage message, ChatProtocol type) {
    return message.type.toString() == type.value;
  }
}
