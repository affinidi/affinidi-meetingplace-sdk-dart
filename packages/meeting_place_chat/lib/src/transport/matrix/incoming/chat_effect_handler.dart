import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';

/// Handles chat-effect events by forwarding them onto the chat stream.
class ChatEffectHandler {
  ChatEffectHandler({required ChatStream chatStream})
    : _chatStream = chatStream;

  final ChatStream _chatStream;

  /// Handles chat-effect events by forwarding them onto the chat stream.
  ///
  /// Chat effects are ephemeral animations. Events replayed from room history
  /// (see [MatrixRoomEvent.isReplay]) are ignored so an old effect does not
  /// re-animate when the session backfills history.
  Future<void> handle(MatrixRoomEvent event) async {
    if (event.isReplay) return;
    _chatStream.pushData(StreamData(event: event.toChatEvent()));
  }
}
