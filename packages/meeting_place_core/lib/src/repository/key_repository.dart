import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

part 'key_repository.g.dart';

@JsonSerializable()
class KeyPair {
  factory KeyPair.fromJson(Map<String, dynamic> json) =>
      _$KeyPairFromJson(json);

  KeyPair({required this.publicKeyBytes, required this.privateKeyBytes});

  @JsonKey(fromJson: _bytesFromJson)
  final Uint8List publicKeyBytes;

  @JsonKey(fromJson: _bytesFromJson)
  final Uint8List privateKeyBytes;

  static Uint8List _bytesFromJson(List<dynamic> json) =>
      Uint8List.fromList(json.cast<int>());
}

abstract interface class KeyRepository {
  Future<int> getLastAccountIndex();

  Future<void> setLastAccountIndex(int index);

  Future<void> saveKeyIdForDid({required String keyId, required String did});

  Future<String?> getKeyIdByDid({required String did});

  Future<void> saveKeyPair({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
    required String did,
  });

  Future<KeyPair?> getKeyPair(String did);
}
