import '../../meeting_place_chat.dart';

class MessageUtils {
  static bool isType(PlainTextMessage message, ChatProtocol type) {
    return message.type.toString() == type.value;
  }
}
