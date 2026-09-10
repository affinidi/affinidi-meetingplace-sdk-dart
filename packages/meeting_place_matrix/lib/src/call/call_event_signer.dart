/// @docImport '../entity/call_outcome_record.dart';
/// @docImport '../transport/matrix/matrix_media_attachment.dart';
library;

import 'package:meeting_place_core/meeting_place_core.dart';

/// Signs and verifies the call-identifying fields of `mpx.call.started` and
/// `mpx.call.outcome` room events, so a receiver can tell whether the sender
/// actually holds the DID key it claims, rather than trusting the sender
/// identity Matrix room membership alone implies.
class CallEventSigner {
  const CallEventSigner({DidPayloadSigner signer = const DidPayloadSigner()})
    : _signer = signer;

  final DidPayloadSigner _signer;

  /// Signs [callFields] (e.g. `{'callId': ...}` or a [CallOutcomeRecord]'s
  /// map) with [senderDidManager]'s authentication key, returning a compact
  /// JWS to embed under `MatrixEventField.callSignature`.
  Future<String> sign({
    required Map<String, dynamic> callFields,
    required DidManager senderDidManager,
  }) async {
    final didDocument = await senderDidManager.getDidDocument();
    final authVm = didDocument.authentication.first;
    final verificationMethodId = authVm.id.startsWith('#')
        ? '${didDocument.id}${authVm.id}'
        : authVm.id;

    return _signer.sign(
      payload: callFields,
      didManager: senderDidManager,
      verificationMethodId: verificationMethodId,
    );
  }

  /// Verifies [signature] over [callFields] was made by [senderDid],
  /// resolved via [didResolver].
  ///
  /// Returns `true` only if the signature is valid AND the signed payload
  /// matches [callFields] exactly, so a signature from a genuine call event
  /// cannot be replayed against different call data.
  Future<bool> verify({
    required String signature,
    required Map<String, dynamic> callFields,
    required String senderDid,
    required DidResolver didResolver,
  }) async {
    final signedPayload = await _signer.verify(
      jws: signature,
      expectedSignerDid: senderDid,
      didResolver: didResolver,
    );
    if (signedPayload == null) return false;

    return _mapsEqual(signedPayload, callFields);
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
