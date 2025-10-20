import '../../core/command/command.dart';
import 'group_send_message.output.dart';

/// Model that represents the output data returned from a successful execution
/// of [GroupSendMessageCommand] operation.
class GroupSendMessageCommand
    extends DiscoveryCommand<GroupSendMessageCommandOutput> {
  /// Creates a new instance of [GroupSendMessageCommand].
  GroupSendMessageCommand({
    required this.offerLink,
    required this.fromDid,
    required this.groupDid,
    required this.messageBase64,
    required this.increaseSequenceNumber,
    required this.notify,
    required this.ephemeral,
    this.forwardExpiryInSeconds,
  });
  final String offerLink;
  final String fromDid;
  final String groupDid;
  final String messageBase64;
  final bool increaseSequenceNumber;
  final bool notify;
  final bool ephemeral;
  final int? forwardExpiryInSeconds;
}
