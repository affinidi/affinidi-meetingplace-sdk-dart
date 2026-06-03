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
    this.stateKey,
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

  /// Matrix `state_key` for state events. For `m.room.member` events this is
  /// the Matrix user ID of the member being affected (e.g. the kicked user
  /// for a `leave` initiated by a different sender). Null for non-state
  /// events.
  final String? stateKey;

  final String? _userId;

  /// Matrix user ID. Derived from [senderDid] for outgoing events;
  /// set directly for incoming events received from the Matrix server.
  String get userId =>
      _userId ?? deriveMatrixUserId(senderDid!, roomId.split(':').last);
}
