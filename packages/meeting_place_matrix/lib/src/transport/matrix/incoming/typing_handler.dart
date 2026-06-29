import 'package:meeting_place_matrix/meeting_place_matrix.dart';

import 'package:meeting_place_chat/meeting_place_chat.dart';

/// Handles `m.typing` events by pushing a [ChatActivityEvent] onto the chat
/// stream for the sender DID populated by core's `MessagingService`.
class TypingHandler {
  TypingHandler({
    required ChatStream chatStream,
    required String ownDid,
    required MeetingPlaceChatSDKLogger logger,
  }) : _chatStream = chatStream,
       _ownDid = ownDid,
       _logger = logger;

  static const String _logkey = 'TypingHandler';

  final ChatStream _chatStream;
  final String _ownDid;
  final MeetingPlaceChatSDKLogger _logger;

  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = event.senderDid;
    _logger.info(
      'Typing event received: eventId=${event.id}, '
      'senderDid=$senderDid, ownDid=$_ownDid, content=${event.content}',
      name: _logkey,
    );
    if (senderDid == null) {
      _logger.warning(
        'Could not resolve sender DID for typing event ${event.id}, '
        'skipping event.',
        name: _logkey,
      );
      return;
    }

    _chatStream.pushData(
      StreamData(
        event: ChatActivityEvent(
          senderDid: senderDid,
          timestamp: event.timestamp,
          createdTime: event.timestamp,
        ),
      ),
    );
  }
}
