import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// Specifies what historical messages to fetch via
/// [MeetingPlaceCoreSDK.fetchHistory].
abstract class HistoryQuery {
  /// Creates a [HistoryQuery].
  const HistoryQuery({required this.ownerDid, this.limit = 50});

  /// DID of the channel owner whose message history is being fetched.
  final String ownerDid;

  /// The maximum number of messages to return.
  final int limit;
}

/// Fetch queued DIDComm messages for the owner DID.
class DidCommHistoryQuery extends HistoryQuery {
  /// Creates a [DidCommHistoryQuery].
  const DidCommHistoryQuery({
    required super.ownerDid,
    super.limit,
    this.mediatorDid,
    this.deleteOnRetrieve = false,
    this.deleteFailedMessages = false,
  });

  /// The mediator's DID to fetch queued messages from. If not provided, the
  /// SDK's configured mediator DID is used.
  final String? mediatorDid;

  /// Whether each message is deleted from the mediator once retrieved.
  final bool deleteOnRetrieve;

  /// Whether messages that fail to process are deleted from the mediator.
  final bool deleteFailedMessages;
}
