import 'package:matrix/matrix.dart' show EventTypes;
import '../../../matrix_outgoing_message.dart';

/// A [MatrixOutgoingMessage] specialised for plain-text chat messages.
///
/// Fixes the Matrix event type to [EventTypes.Message] and builds the
/// standard `m.text` content map from the supplied `text`.
class TextMessageRoomEvent extends MatrixOutgoingMessage {
  TextMessageRoomEvent({
    required super.senderDid,
    required String text,
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: {'body': text, 'msgtype': 'm.text'},
       );
}
