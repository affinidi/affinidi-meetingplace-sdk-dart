import 'package:meeting_place_core/meeting_place_core.dart';

/// An [OutgoingMessage] routed through the Matrix transport.
///
/// Carries everything needed to send a Matrix room event: event [type]
/// (e.g. a chat protocol URI, `m.read`, `m.reaction`, `m.room.redaction`,
/// `m.typing`) and JSON [content]. The target room is resolved from the
/// channel owned by [senderDid].
abstract class MatrixOutgoingMessage extends OutgoingMessage {
  const MatrixOutgoingMessage({
    required super.senderDid,
    required this.type,
    required this.content,
    this.notification,
  });

  /// Matrix event type (e.g. `m.read`, `m.reaction`, `m.room.redaction`,
  /// `m.typing`).
  final String type;

  /// JSON content of the Matrix event. Must be serializable to
  /// `Map<String, dynamic>`.
  final Map<String, dynamic> content;

  /// When set, the SDK fires a fire-and-forget control-plane channel
  /// notification after the room event is delivered to the homeserver.
  final ChannelNotification? notification;
}
