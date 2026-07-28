import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_models.freezed.dart';
part 'key_models.g.dart';

@freezed
abstract class VtaKeyRecord with _$VtaKeyRecord {
  const factory VtaKeyRecord({
    @JsonKey(name: 'key_id') required String keyId,
    @JsonKey(name: 'key_type') required String keyType,
    @JsonKey(name: 'context_id') String? contextId,
    String? label,
    String? status,
  }) = _VtaKeyRecord;

  factory VtaKeyRecord.fromJson(Map<String, dynamic> json) =>
      _$VtaKeyRecordFromJson(json);
}
