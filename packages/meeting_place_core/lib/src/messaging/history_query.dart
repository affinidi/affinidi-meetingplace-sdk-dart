/// Specifies what historical messages to fetch via
/// [MeetingPlaceCoreSDK.fetchHistory].
sealed class HistoryQuery {
  const HistoryQuery({required this.receiverDid, this.limit = 50});

  final String receiverDid;
  final int limit;
}

/// Fetch the most recent events from a Matrix room.
class MatrixRoomHistoryQuery extends HistoryQuery {
  const MatrixRoomHistoryQuery({
    required super.receiverDid,
    required this.roomId,
    super.limit,
  });

  final String roomId;
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
