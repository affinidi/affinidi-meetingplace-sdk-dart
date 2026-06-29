import 'package:meeting_place_core/meeting_place_core.dart';

/// An [IncomingMessage] received from the Matrix transport.
class MatrixIncomingMessage extends IncomingMessage {
  const MatrixIncomingMessage({
    required super.senderDid,
    required super.timestamp,
    required this.roomId,
    required this.eventId,
    required this.type,
    required this.content,
    this.isFromMe = false,
    this.stateKey,
  });

  final String roomId;
  final String eventId;
  final String type;
  final Map<String, dynamic> content;
  final bool isFromMe;

  /// Matrix `state_key` for state events. For `m.room.member` events this is
  /// the Matrix user ID of the user being affected. Null for non-state events.
  final String? stateKey;
}
