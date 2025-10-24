import 'package:json_annotation/json_annotation.dart';
import '../protocol/v_card/v_card.dart';

part 'group_member.g.dart';

enum GroupMemberStatus {
  pendingApproval,
  pendingInauguration,
  approved,
  rejected,
  error,
  deleted,
}

enum GroupMembershipType { admin, member }

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMember {
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return _$GroupMemberFromJson(json);
  }

  GroupMember({
    required this.did,
    required this.dateAdded,
    required this.status,
    required this.membershipType,
    required this.vCard,
    required this.publicKey,
  });

  final String did;
  final DateTime dateAdded;
  final GroupMembershipType membershipType;
  final String publicKey;
  VCard vCard;

  GroupMemberStatus status;

  Map<String, dynamic> toJson() {
    return _$GroupMemberToJson(this);
  }

  GroupMember copyWith({
    String? did,
    DateTime? dateAdded,
    GroupMemberStatus? status,
    GroupMembershipType? membershipType,
    VCard? vCard,
    String? publicKey,
  }) {
    return GroupMember(
      did: did ?? this.did,
      dateAdded: dateAdded ?? this.dateAdded,
      status: status ?? this.status,
      membershipType: membershipType ?? this.membershipType,
      vCard: vCard ?? this.vCard,
      publicKey: publicKey ?? this.publicKey,
    );
  }
}
