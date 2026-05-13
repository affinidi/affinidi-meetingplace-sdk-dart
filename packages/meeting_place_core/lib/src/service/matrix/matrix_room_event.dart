import 'matrix_user_id_binding.dart';

class MatrixRoomEvent {
  MatrixRoomEvent({
    required this.id,
    required this.type,
    this.senderDid,
    String? userId,
    required this.roomId,
    required this.content,
    required this.timestamp,
    this.isFromMe = false,
  }) : assert(
         senderDid != null || userId != null,
         'Either senderDid or userId must be provided',
       ),
       _userId = userId;

  final String id;
  final String type;

  /// DID of the sender. Set for outgoing events created by this client.
  /// Null for incoming events where only the Matrix user ID is known.
  final String? senderDid;

  final String roomId;
  final Map<String, dynamic> content;
  final DateTime timestamp;
  final bool isFromMe;

  final String? _userId;

  /// Matrix user ID. Derived from [senderDid] for outgoing events;
  /// set directly for incoming events received from the Matrix server.
  String get userId =>
      _userId ?? deriveMatrixUserId(senderDid!, roomId.split(':').last);
}
