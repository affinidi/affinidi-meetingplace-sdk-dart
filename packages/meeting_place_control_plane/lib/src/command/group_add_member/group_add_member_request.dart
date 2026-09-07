import '../../core/command/command.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'add_group_member_result.dart';

/// Model that represents the request sent for the [GroupAddMemberRequest]
/// operation.
class GroupAddMemberRequest extends DiscoveryCommand<AddGroupMemberResult> {
  /// Creates a new instance of [GroupAddMemberRequest].
  GroupAddMemberRequest({
    required this.mnemonic,
    required this.groupId,
    required this.memberDid,
    required this.acceptOfferDid,
    required this.offerLink,
    this.contactCard,
  });

  /// The mnemonic identifier of the group offer being accepted.
  final String mnemonic;

  /// The identifier of the group to add the member to.
  final String groupId;

  /// The DID of the member being added to the group.
  final String memberDid;

  /// The DID used to accept the offer on behalf of the new member.
  final String acceptOfferDid;

  /// The link of the group offer being accepted.
  final String offerLink;

  /// The contact card sharing the identity of the new member, if any.
  final ContactCard? contactCard;
}
