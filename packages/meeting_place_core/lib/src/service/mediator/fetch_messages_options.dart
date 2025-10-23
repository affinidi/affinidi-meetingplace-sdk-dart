/// Options for fetching messages from the mediator.
class FetchMessagesOptions {
  const FetchMessagesOptions({
    this.batchSize = 100,
    this.deleteOnRetrieve = false,
    this.deleteFailedMessages = false,
    this.startFrom,
    this.filterByMessageTypes = const [],
  });

  /// Number of records to fetch from mediator at once.
  final int batchSize;

  /// Whether to delete messages from the mediator after retrieval.
  ///
  /// **Important:**
  /// If set to `true`, all retrieved messages will be removed from the
  /// mediator.
  ///
  /// If `filterByMessageTypes` is also set, messages of *other* types
  /// (not matching the filter) will still be deleted.
  final bool deleteOnRetrieve;

  /// Whether to delete messages that failed to be processed.
  final bool deleteFailedMessages;

  /// Optional date-time to start fetching messages from.
  final DateTime? startFrom;

  /// Optional list of message types to filter messages by.
  final List<String> filterByMessageTypes;
}
