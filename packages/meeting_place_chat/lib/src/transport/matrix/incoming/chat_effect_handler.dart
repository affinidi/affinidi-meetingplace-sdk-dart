import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';

/// Handles chat-effect events by forwarding them onto the chat stream.
class ChatEffectHandler {
  ChatEffectHandler({required ChatStream chatStream})
    : _chatStream = chatStream;

  final ChatStream _chatStream;

  Future<void> handle(MatrixRoomEvent event) async {
    _chatStream.pushData(StreamData(event: event.toChatEvent()));
  }
}
