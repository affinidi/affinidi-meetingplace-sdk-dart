import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

/// Test double for [BaseKeyProvider] that no-ops all key operations.
///
/// [BaseKeyProvider.create] calls `rtc.frameCryptorFactory` which is a platform
/// channel unavailable in unit tests. Use this fake to bypass that call and
/// keep tests in the Dart VM.
class FakeBaseKeyProvider implements BaseKeyProvider {
  @override
  Future<void> setSharedKey(String key, {int? keyIndex}) async {}

  @override
  Future<Uint8List> ratchetSharedKey({int? keyIndex}) async =>
      Uint8List.fromList([]);

  @override
  Future<Uint8List> exportSharedKey({int? keyIndex}) async =>
      Uint8List.fromList([]);

  @override
  Future<void> setKey(
    String key, {
    String? participantId,
    int? keyIndex,
  }) async {}

  @override
  Future<void> setRawKey(
    Uint8List key, {
    String? participantId,
    int? keyIndex,
  }) async {}

  @override
  Future<Uint8List> ratchetKey(String participantId, int? keyIndex) async =>
      Uint8List.fromList([]);

  @override
  Future<Uint8List> exportKey(String participantId, int? keyIndex) async =>
      Uint8List.fromList([]);

  @override
  Uint8List? get sharedKey => null;

  @override
  Future<void> setSifTrailer(Uint8List trailer) async {}

  @override
  rtc.KeyProvider get keyProvider =>
      throw UnimplementedError('keyProvider is not needed in tests');

  @override
  rtc.KeyProviderOptions get options =>
      throw UnimplementedError('options is not needed in tests');

  @override
  int getLatestIndex(String participantId) => 0;
}
