import 'package:json_annotation/json_annotation.dart';

part 'group_deletion_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupDeletionBody {
  factory GroupDeletionBody.fromJson(Map<String, dynamic> json) =>
      _$GroupDeletionBodyFromJson(json);

  GroupDeletionBody({required this.groupId});

  @JsonKey(name: 'group_id')
  final String groupId;

  Map<String, dynamic> toJson() => _$GroupDeletionBodyToJson(this);
}
