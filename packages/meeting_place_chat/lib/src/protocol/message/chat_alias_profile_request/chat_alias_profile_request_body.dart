import 'package:json_annotation/json_annotation.dart';

part 'chat_alias_profile_request_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatAliasProfileRequestBody {
  factory ChatAliasProfileRequestBody.fromJson(Map<String, dynamic> json) =>
      _$ChatAliasProfileRequestBodyFromJson(json);

  ChatAliasProfileRequestBody({required this.profileHash});

  @JsonKey(name: 'profile_hash')
  final String profileHash;

  Map<String, dynamic> toJson() => _$ChatAliasProfileRequestBodyToJson(this);
}
