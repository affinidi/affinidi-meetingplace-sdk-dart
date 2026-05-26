import 'package:meeting_place_core/meeting_place_core.dart';

/// Contract for an incoming [MatrixRoomEvent] handler. Implementations are
/// dispatched to by `IncomingRoomEventRouter` based on event type.
abstract interface class RoomEventHandler {
  Future<void> handle(MatrixRoomEvent event);
}
