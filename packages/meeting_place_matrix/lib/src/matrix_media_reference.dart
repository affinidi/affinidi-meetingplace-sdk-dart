import 'package:meeting_place_core/meeting_place_core.dart';

/// Reference to a media payload posted as a Matrix `m.room.message` event.
final class MatrixEventMediaReference extends MediaReference {
  const MatrixEventMediaReference(this.eventId);

  /// Server-assigned event id returned by `MessagingService.sendMediaMessage`
  /// for Matrix channels.
  final String eventId;

  @override
  String get fileId => eventId;
}
