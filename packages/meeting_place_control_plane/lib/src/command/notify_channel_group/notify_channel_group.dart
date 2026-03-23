import '../../core/command/command.dart';
import 'notify_channel_group_output.dart';

/// Model that represents the request sent for the [NotifyChannelGroupCommand]
/// operation.
class NotifyChannelGroupCommand
    extends DiscoveryCommand<NotifyChannelGroupCommandOutput> {
  /// Creates a new instance of [NotifyChannelGroupCommand].
  NotifyChannelGroupCommand({required this.groupId, required this.type});

  final String groupId;
  final String type;
}
