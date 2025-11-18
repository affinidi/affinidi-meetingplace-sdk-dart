import 'package:json_annotation/json_annotation.dart';

part 'chat_effect_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatEffectBody {
  factory ChatEffectBody.fromJson(Map<String, dynamic> json) =>
      _$ChatEffectBodyFromJson(json);

  ChatEffectBody({required this.effect});

  @JsonKey(name: 'effect')
  final String effect;

  Map<String, dynamic> toJson() => _$ChatEffectBodyToJson(this);
}
