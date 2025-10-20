class FetchMessagesOptions {
  const FetchMessagesOptions({
    this.batchSize = 25,
    this.deleteOnRetrieve = false,
    this.deleteFailedMessages = false,
    this.startFrom,
    this.filterByMessageTypes = const [],
  });

  final int batchSize;
  final bool deleteOnRetrieve;
  final bool deleteFailedMessages;
  final DateTime? startFrom;
  final List<String> filterByMessageTypes;
}
