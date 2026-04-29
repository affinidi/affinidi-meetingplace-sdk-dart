import '../../core/command/command.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'group_add_member_output.dart';

/// Model that represents the request sent for the [GroupAddMemberCommand]
/// operation.
class GroupAddMemberCommand
    extends DiscoveryCommand<GroupAddMemberCommandOutput> {
  /// Creates a new instance of [GroupAddMemberCommand].
  GroupAddMemberCommand({
    required this.mnemonic,
    required this.groupId,
    required this.memberDid,
    required this.acceptOfferDid,
    required this.offerLink,
    required this.publicKey,
    required this.reencryptionKey,
    this.contactCard,
    this.trustCredentialProof,
    this.trustScope,
    this.trustIssuerDid,
    this.trustActorDid,
    this.trustGroupId,
  });
  final String mnemonic;
  final String groupId;
  final String memberDid;
  final String acceptOfferDid;
  final String offerLink;
  final String publicKey;
  final String reencryptionKey;
  final ContactCard? contactCard;
  final String? trustCredentialProof;
  final String? trustScope;
  final String? trustIssuerDid;
  final String? trustActorDid;
  final String? trustGroupId;
}
