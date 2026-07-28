import '../errors/vta_client_exception.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vta_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VtaConfig {
  const VtaConfig({
    required this.baseUrl,
    required this.vtaDid,
    this.mediatorDid,
  });

  final String baseUrl;
  final String vtaDid;
  final String? mediatorDid;

  factory VtaConfig.fromJson(Map<String, dynamic> json) =>
      _$VtaConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VtaConfigToJson(this);
}

extension VtaConfigValidation on VtaConfig {
  void validate() {
    if (baseUrl.trim().isEmpty || vtaDid.trim().isEmpty) {
      throw const VtaValidationException(
        'baseUrl and vtaDid must be non-empty.',
        code: 'e.vta.config.invalid',
      );
    }
  }
}
