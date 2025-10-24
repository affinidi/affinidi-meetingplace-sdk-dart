import 'package:json_annotation/json_annotation.dart';

part 'mediator_config.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class MediatorConfig {
  MediatorConfig({
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    this.secondsBeforeExpiryReauthenticate,
  });

  factory MediatorConfig.fromJson(Map<String, dynamic> json) {
    return _$MediatorConfigFromJson(json);
  }
  final String mediatorDid;
  final String mediatorEndpoint;
  final String mediatorWSSEndpoint;
  final int? secondsBeforeExpiryReauthenticate;

  Map<String, dynamic> toJson() {
    return _$MediatorConfigToJson(this);
  }
}
