import '../service/matrix/matrix_room_event.dart';

class MatrixTransport {
  MatrixTransport();

  Future<String?> sendRoomEvent(MatrixRoomEvent event) {
    return Future.value(null);
  }

  Stream<MatrixRoomEvent> subscribeToRoom({
    required String roomId,
    required String receiverDid,
  }) async* {}

  Future<List<MatrixRoomEvent>> fetchRoomHistory({
    required String roomId,
    required String receiverDid,
    int limit = 50,
  }) {
    return Future.value([]);
  }
}
