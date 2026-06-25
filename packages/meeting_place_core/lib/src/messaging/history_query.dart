import '../../meeting_place_core.dart' show MeetingPlaceCoreSDK;
import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// Specifies what historical messages to fetch via
/// [MeetingPlaceCoreSDK.fetchHistory].
sealed class HistoryQuery {
  const HistoryQuery({required this.receiverDid, this.limit = 50});

  final String receiverDid;
  final int limit;
}

/// Fetch the most recent events from a Matrix room. The room is resolved
/// from the channel owned by [receiverDid].
class MatrixRoomHistoryQuery extends HistoryQuery {
  const MatrixRoomHistoryQuery({
    required super.receiverDid,
    super.limit,
    this.sinceEventId,
    this.updateChannelSyncMarker = true,
  });

  /// Optional anchor event id. When provided, fetches events that arrived
  /// after this event (exclusive) by resolving a fresh pagination token via
  /// the `/context` endpoint. Event IDs are stable and never expire. When
  /// null, falls back to the channel's persisted `matrixSyncMarker`.
  final String? sinceEventId;

  /// Whether to update the channel's `matrixSyncMarker` to the latest
  /// delivered event. Defaults to true. Set to false when the caller wants to
  /// fetch history without advancing the channel's marker.
  final bool updateChannelSyncMarker;
}

/// Fetch queued DIDComm messages for the receiver DID.
class DidCommHistoryQuery extends HistoryQuery {
  const DidCommHistoryQuery({
    required super.receiverDid,
    super.limit,
    this.mediatorDid,
    this.deleteOnRetrieve = false,
    this.deleteFailedMessages = false,
  });

  final String? mediatorDid;
  final bool deleteOnRetrieve;
  final bool deleteFailedMessages;
}
