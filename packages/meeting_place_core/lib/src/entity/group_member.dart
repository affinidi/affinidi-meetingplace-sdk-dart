import 'package:json_annotation/json_annotation.dart';
import '../protocol/contact_card/contact_card.dart';

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
  factory GroupMember.pendingMember({
    required String did,
    required String publicKey,
    required ContactCard contactCard,
  }) {
    return GroupMember(
      did: did,
      publicKey: publicKey,
      dateAdded: DateTime.now().toUtc(),
      status: GroupMemberStatus.pendingApproval,
      membershipType: GroupMembershipType.member,
      contactCard: contactCard,
    );
  }

  factory GroupMember.admin({
    required String did,
    required String publicKey,
    required ContactCard contactCard,
  }) {
    return GroupMember(
      did: did,
      publicKey: publicKey,
      dateAdded: DateTime.now().toUtc(),
      status: GroupMemberStatus.approved,
      membershipType: GroupMembershipType.admin,
      contactCard: contactCard,
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return _$GroupMemberFromJson(json);
  }

  GroupMember({
    required this.did,
    required this.dateAdded,
    required this.status,
    required this.membershipType,
    required this.contactCard,
    required this.publicKey,
  });

  final String did;
  final DateTime dateAdded;
  final GroupMembershipType membershipType;
  final String publicKey;
  ContactCard contactCard;

  GroupMemberStatus status;

  Map<String, dynamic> toJson() {
    return _$GroupMemberToJson(this);
  }

  GroupMember copyWith({
    String? did,
    DateTime? dateAdded,
    GroupMemberStatus? status,
    GroupMembershipType? membershipType,
    ContactCard? card,
    String? publicKey,
  }) {
    return GroupMember(
      did: did ?? this.did,
      dateAdded: dateAdded ?? this.dateAdded,
      status: status ?? this.status,
      membershipType: membershipType ?? this.membershipType,
      contactCard: card ?? contactCard,
      publicKey: publicKey ?? this.publicKey,
    );
  }
}
