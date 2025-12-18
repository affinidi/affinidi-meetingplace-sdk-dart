import 'package:json_annotation/json_annotation.dart';

part 'group_member_deregistration_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMemberDeregistrationBody {
  factory GroupMemberDeregistrationBody.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDeregistrationBodyFromJson(json);

  GroupMemberDeregistrationBody({
    required this.groupId,
    required this.memberDid,
  });

  @JsonKey(name: 'group_id')
  final String groupId;

  @JsonKey(name: 'member_did')
  final String memberDid;

  Map<String, dynamic> toJson() => _$GroupMemberDeregistrationBodyToJson(this);
}
