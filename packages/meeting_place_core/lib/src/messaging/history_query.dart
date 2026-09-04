import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// Specifies what historical messages to fetch via
/// [MeetingPlaceCoreSDK.fetchHistory].
abstract class HistoryQuery {
  const HistoryQuery({required this.ownerDid, this.limit = 50});

  final String ownerDid;
  final int limit;
}

/// Fetch queued DIDComm messages for the owner DID.
class DidCommHistoryQuery extends HistoryQuery {
  const DidCommHistoryQuery({
    required super.ownerDid,
    super.limit,
    this.mediatorDid,
    this.deleteOnRetrieve = false,
    this.deleteFailedMessages = false,
  });

  final String? mediatorDid;
  final bool deleteOnRetrieve;
  final bool deleteFailedMessages;
}
