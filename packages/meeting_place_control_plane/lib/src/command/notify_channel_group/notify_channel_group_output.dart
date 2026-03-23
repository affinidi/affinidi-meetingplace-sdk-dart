/// Model that represents the output data returned from a successful execution
/// of [NotifyChannelGroupCommand] operation.
class NotifyChannelGroupCommandOutput {
  /// Creates a new instance of [NotifyChannelGroupCommandOutput].
  NotifyChannelGroupCommandOutput({
    required this.success,
    required this.notifiedCount,
  });

  final bool success;
  final int notifiedCount;
}
