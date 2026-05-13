import 'package:matrix/matrix.dart' show EventTypes;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

/// A [MatrixRoomEvent] specialised for plain-text chat messages.
///
/// Fixes the Matrix event type to [EventTypes.Message] and builds the
/// standard `m.text` content map from the supplied [text].
class TextMessageRoomEvent extends MatrixRoomEvent {
  TextMessageRoomEvent({
    required super.id,
    required super.sender,
    required super.roomId,
    required super.timestamp,
    required String text,
  }) : super(
         type: EventTypes.Message,
         content: {'body': text, 'msgtype': 'm.text'},
       );

  factory TextMessageRoomEvent.create({
    required String sender,
    required String roomId,
    required String text,
  }) => TextMessageRoomEvent(
    id: const Uuid().v4(),
    sender: sender,
    roomId: roomId,
    text: text,
    timestamp: DateTime.now().toUtc(),
  );
}
