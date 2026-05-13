import 'package:matrix/matrix.dart' as matrix;

class MatrixRoomEvent {
  MatrixRoomEvent({
    required this.id,
    required this.type,
    required this.sender,
    required this.roomId,
    required this.content,
    required this.timestamp,
    this.isFromMe = false,
  });

  final String id;
  final String type;
  final String sender;
  final String roomId;
  final Map<String, dynamic> content;
  final DateTime timestamp;
  final bool isFromMe;
}
