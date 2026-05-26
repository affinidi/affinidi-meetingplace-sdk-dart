import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../events/chat_event_conversion.dart';
import 'room_event_handler.dart';

/// Handles chat-effect events by forwarding them onto the chat stream.
class ChatEffectHandler implements RoomEventHandler {
  ChatEffectHandler({required ChatStream chatStream})
    : _chatStream = chatStream;

  final ChatStream _chatStream;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    _chatStream.pushData(StreamData(event: event.toChatEvent()));
  }
}
