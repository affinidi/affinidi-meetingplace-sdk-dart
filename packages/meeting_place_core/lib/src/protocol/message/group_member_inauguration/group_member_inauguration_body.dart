import 'package:json_annotation/json_annotation.dart';

import 'group_member_inauguration_member.dart';

part 'group_member_inauguration_body.g.dart';

/// The body of a group-member-inauguration message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberInaugurationBody {
  /// Creates a [GroupMemberInaugurationBody] from its JSON representation.
  factory GroupMemberInaugurationBody.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberInaugurationBodyFromJson(json);

  /// Creates a [GroupMemberInaugurationBody].
  GroupMemberInaugurationBody({
    required this.memberDid,
    required this.groupDid,
    required this.groupId,
    required this.adminDids,
    required this.members,
  });

  /// The DID of the member being inaugurated.
  @JsonKey(name: 'member_did')
  final String memberDid;

  /// The DID of the group.
  @JsonKey(name: 'group_did')
  final String groupDid;

  /// The id of the group.
  @JsonKey(name: 'group_id')
  final String groupId;

  /// The DIDs of the group's admins.
  @JsonKey(name: 'admin_dids')
  final List<String> adminDids;

  /// The group's current members.
  @JsonKey(name: 'members')
  final List<GroupMemberInaugurationMember> members;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$GroupMemberInaugurationBodyToJson(this);
}
