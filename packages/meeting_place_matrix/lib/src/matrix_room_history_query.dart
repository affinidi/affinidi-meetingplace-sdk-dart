import 'package:meeting_place_core/meeting_place_core.dart';

/// Fetch the most recent events from a Matrix room. The room is resolved
/// from the channel owned by [receiverDid].
class MatrixRoomHistoryQuery extends HistoryQuery {
  const MatrixRoomHistoryQuery({
    required super.receiverDid,
    super.limit,
    this.since,
    this.updateChannelSyncMarker = true,
  });

  /// Optional anchor event id. When provided, fetches events that arrived
  /// after this event (exclusive) by resolving a fresh pagination token via
  /// the `/context` endpoint. Event IDs are stable and never expire. When
  /// null, falls back to the channel's persisted `messageSyncMarker`.
  final String? since;

  /// Whether to update the channel's `messageSyncMarker` to the latest
  /// delivered event. Defaults to true. Set to false when the caller wants to
  /// fetch history without advancing the channel's marker.
  final bool updateChannelSyncMarker;
}
