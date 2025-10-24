import 'package:json_annotation/json_annotation.dart';

part 'group_membership_finalised.g.dart';

/// Notification event indicating that group membership has been finalized,
/// such as when an admin approves a join request.
///
/// Typical handling:
/// - Update the group member's status
/// - Notify the member of the finalized membership
/// - Update the user interface to reflect the new group membership state
@JsonSerializable(includeIfNull: false, createToJson: false)
class GroupMembershipFinalised {
  GroupMembershipFinalised({
    required this.id,
    required this.offerLink,
    this.pendingCount = 0,
    this.startSeqNo = 0,
    this.isEmpty = false,
  });

  factory GroupMembershipFinalised.fromJson(Map<String, dynamic> json) {
    return _$GroupMembershipFinalisedFromJson(json);
  }
  final String id;
  final String offerLink;
  final int pendingCount;
  final int startSeqNo;
  final bool isEmpty;
}
