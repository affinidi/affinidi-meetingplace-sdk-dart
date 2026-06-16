import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';

class PresenceHandler {
  const PresenceHandler({required this.chatStream});

  final ChatStream chatStream;

  Future<void> handle(MatrixRoomEvent event) async {
    chatStream.pushData(
      StreamData(event: ChatPresenceEvent(timestamp: event.timestamp)),
    );
  }
}
