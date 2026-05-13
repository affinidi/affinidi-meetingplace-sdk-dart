import '../../meeting_place_core.dart';
import '../sdk/sdk_error_handler.dart';

class MatrixTransport {
  MatrixTransport({
    required MatrixService matrixService,
    required SDKErrorHandler errorHandler,
    required Future<DidManager> Function(String did) getDidManager,
  }) : _matrixService = matrixService,
       _errorHandler = errorHandler,
       _getDidManager = getDidManager;

  final MatrixService _matrixService;
  final SDKErrorHandler _errorHandler;
  final Future<DidManager> Function(String did) _getDidManager;

  Future<String?> sendRoomEvent(MatrixRoomEvent event) {
    return _errorHandler.handleError(() async {
      final senderDid = event.senderDid;

      if (senderDid == null) {
        throw StateError('Room event sender did empty.');
      }

      final didManager = await _getDidManager(event.senderDid!);
      return _matrixService.sendRoomEvent(
        event.roomId,
        event.type,
        event.content,
        didManager: didManager,
      );
    });
  }

  Future<void> sendTypingNotification({
    required String roomId,
    required String senderDid,
    int? timeoutMs,
  }) {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(senderDid);
      return _matrixService.enableTyping(
        roomId,
        didManager: didManager,
        timeoutMs: timeoutMs,
      );
    });
  }

  Future<void> disableTyping({
    required String roomId,
    required String senderDid,
  }) {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(senderDid);
      return _matrixService.disableTyping(roomId, didManager: didManager);
    });
  }

  Future<Stream<MatrixRoomEvent>> subscribeToRoom({
    required String roomId,
    required String receiverDid,
    MatrixSubscriptionOptions options = const MatrixSubscriptionOptions(),
  }) async {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(receiverDid);
      return _matrixService.subscribeToRoom(
        roomId,
        didManager: didManager,
        options: options,
      );
    });
  }

  Future<List<MatrixRoomEvent>> fetchRoomHistory({
    required String roomId,
    required String receiverDid,
    int limit = 50,
  }) {
    return _errorHandler.handleError(() async {
      final didManager = await _getDidManager(receiverDid);
      return _matrixService.fetchRoomHistory(
        roomId,
        didManager: didManager,
        limit: limit,
      );
    });
  }
}
