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
    this.sinceEventId,
    super.limit,
  });

  /// Optional anchor event id. When provided, only events that come after
  /// (i.e., were stored more recently than) this event id are returned. When
  /// null, the call falls back to the channel's persisted `matrixSyncMarker`.
  /// Use this when the caller (e.g., a chat session) owns its own cursor —
  /// typically the latest persisted message's transport id — independent of
  /// the channel-level sync marker advanced by the push pipeline.
  final String? sinceEventId;
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
