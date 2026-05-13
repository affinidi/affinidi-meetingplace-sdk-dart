import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../meeting_place_chat.dart';
import '../../core/matrix_user_id_cache.dart';
import 'room_event_handler.dart';

/// Handles `m.typing` events by resolving the sender DID and pushing a
/// [ChatActivityEvent] onto the chat stream.
class TypingHandler implements RoomEventHandler {
  TypingHandler({
    required MatrixUserIdCache didCache,
    required ChatStream chatStream,
    required String ownDid,
    required MeetingPlaceChatSDKLogger logger,
  }) : _didCache = didCache,
       _chatStream = chatStream,
       _ownDid = ownDid,
       _logger = logger;

  static const String _logkey = 'TypingHandler';

  final MatrixUserIdCache _didCache;
  final ChatStream _chatStream;
  final String _ownDid;
  final MeetingPlaceChatSDKLogger _logger;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = _didCache.resolve(event.userId);
    _logger.info(
      'Typing event received: eventId=${event.id}, userId=${event.userId}, '
      'resolvedSenderDid=$senderDid, ownDid=$_ownDid, content=${event.content}',
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
