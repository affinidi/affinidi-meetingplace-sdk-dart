import 'package:matrix/matrix.dart' show EventTypes;
import 'package:meeting_place_core/meeting_place_core.dart';

/// A [MatrixOutgoingMessage] specialised for plain-text chat messages.
///
/// Fixes the Matrix event type to [EventTypes.Message] and builds the
/// standard `m.text` content map from the supplied [text].
class TextMessageRoomEvent extends MatrixOutgoingMessage {
  TextMessageRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String text,
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: {'body': text, 'msgtype': 'm.text'},
       );
}
