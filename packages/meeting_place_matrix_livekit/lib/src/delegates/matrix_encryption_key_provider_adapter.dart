import 'dart:typed_data';

import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart' as matrix;

/// Adapter that maps [lk.BaseKeyProvider] (livekit_client) to
/// [matrix.EncryptionKeyProvider] so MatrixRTC can push per-participant E2EE
/// keys into the LiveKit FrameCryptor layer.
class MatrixEncryptionKeyProviderAdapter
    implements matrix.EncryptionKeyProvider {
  const MatrixEncryptionKeyProviderAdapter(this._keyProvider);

  final lk.BaseKeyProvider _keyProvider;

  @override
  Future<void> onSetEncryptionKey(
    matrix.CallParticipant participant,
    Uint8List key,
    int index,
  ) => _keyProvider.setRawKey(
    key,
    participantId: participant.id,
    keyIndex: index,
  );

  @override
  Future<Uint8List> onRatchetKey(
    matrix.CallParticipant participant,
    int index,
  ) => _keyProvider.ratchetKey(participant.id, index);

  @override
  Future<Uint8List> onExportKey(
    matrix.CallParticipant participant,
    int index,
  ) => _keyProvider.exportKey(participant.id, index);
}
