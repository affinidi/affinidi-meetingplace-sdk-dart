import 'package:json_annotation/json_annotation.dart';

part 'sign_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SignResponse {
  const SignResponse({
    required this.signature,
    this.algorithm,
    this.keyId,
  });

  final String signature;
  final String? algorithm;
  final String? keyId;

  factory SignResponse.fromJson(Map<String, dynamic> json) =>
      _$SignResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SignResponseToJson(this);
}
