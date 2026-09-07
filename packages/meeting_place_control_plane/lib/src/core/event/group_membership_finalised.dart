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
  /// Creates a new instance of [GroupMembershipFinalised].
  GroupMembershipFinalised({
    required this.id,
    required this.offerLink,
    this.pendingCount = 0,
    this.startSeqNo = 0,
    this.isEmpty = false,
  });

  /// Creates a [GroupMembershipFinalised] from the given JSON [json].
  factory GroupMembershipFinalised.fromJson(Map<String, dynamic> json) {
    return _$GroupMembershipFinalisedFromJson(json);
  }

  /// The unique identifier of this event.
  final String id;

  /// A link identifying the group offer this membership belongs to.
  final String offerLink;

  /// The number of pending, unprocessed membership items.
  final int pendingCount;

  /// The sequence number to resume fetching pending memberships from.
  final int startSeqNo;

  /// Whether there is no pending membership data to report.
  final bool isEmpty;
}
