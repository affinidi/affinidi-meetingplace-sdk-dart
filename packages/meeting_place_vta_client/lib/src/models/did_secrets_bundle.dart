import 'package:freezed_annotation/freezed_annotation.dart';

part 'did_secrets_bundle.freezed.dart';
part 'did_secrets_bundle.g.dart';

@freezed
abstract class DidSecretEntry with _$DidSecretEntry {
  const factory DidSecretEntry({
    @JsonKey(name: 'key_id') required String keyId,
    @JsonKey(name: 'key_type') required String keyType,
    @JsonKey(name: 'private_key_multibase') required String privateKeyMultibase,
  }) = _DidSecretEntry;

  factory DidSecretEntry.fromJson(Map<String, dynamic> json) =>
      _$DidSecretEntryFromJson(json);
}

@freezed
abstract class DidSecretsBundle with _$DidSecretsBundle {
  const factory DidSecretsBundle({
    required String did,
    required List<DidSecretEntry> secrets,
  }) = _DidSecretsBundle;

  factory DidSecretsBundle.fromJson(Map<String, dynamic> json) =>
      _$DidSecretsBundleFromJson(json);
}
