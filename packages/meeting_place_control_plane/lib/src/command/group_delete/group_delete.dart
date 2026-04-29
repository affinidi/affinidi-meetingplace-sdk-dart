import '../../core/command/command.dart';
import 'group_delete_output.dart';

/// Model that represents the request sent for the [GroupDeleteCommand]
/// operation.
class GroupDeleteCommand extends DiscoveryCommand<GroupDeleteCommandOutput> {
  /// Creates a new instance of [GroupDeleteCommand].
  GroupDeleteCommand({
    required this.groupId,
    required this.messageBase64,
    this.actorDid,
    this.trustCredentialProof,
    this.trustScope,
    this.trustIssuerDid,
  });
  final String groupId;
  final String messageBase64;
  final String? actorDid;
  final String? trustCredentialProof;
  final String? trustScope;
  final String? trustIssuerDid;
}
