import 'package:json_annotation/json_annotation.dart';

part 'chat_alias_profile_hash_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatAliasProfileHashBody {
  factory ChatAliasProfileHashBody.fromJson(Map<String, dynamic> json) =>
      _$ChatAliasProfileHashBodyFromJson(json);

  ChatAliasProfileHashBody({required this.profileHash});

  @JsonKey(name: 'profile_hash')
  final String profileHash;

  Map<String, dynamic> toJson() => _$ChatAliasProfileHashBodyToJson(this);
}
