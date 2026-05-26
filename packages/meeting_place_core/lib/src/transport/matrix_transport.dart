import '../service/matrix/matrix_room_event.dart';

class MatrixTransport {
  MatrixTransport();

  Future<String?> sendRoomEvent(MatrixRoomEvent event) {
    throw UnimplementedError(
      'sendRoomEvent is not implemented in MatrixTransport',
    );
  }

  Stream<MatrixRoomEvent> subscribeToRoom({
    required String roomId,
    required String receiverDid,
  }) async* {
    throw UnimplementedError(
      'subscribeToRoom is not implemented in MatrixTransport',
    );
  }

  Future<List<MatrixRoomEvent>> fetchRoomHistory({
    required String roomId,
    required String receiverDid,
    int limit = 50,
  }) {
    throw UnimplementedError(
      'fetchRoomHistory is not implemented in MatrixTransport',
    );
  }
}
