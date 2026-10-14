import 'dart:typed_data';

import 'package:ssi/ssi.dart';

/// Signs Trust Task documents on behalf of a single verification method.
abstract interface class TrustTaskSigner {
  /// DID of the signer, used as the document issuer.
  String get did;

  /// Verification method id placed in the proof.
  String get verificationMethod;

  /// Signs [data] and returns the raw signature bytes.
  Future<Uint8List> sign(Uint8List data);
}

/// A [TrustTaskSigner] backed by an Ed25519 key exposed as a `did:key`.
///
/// Used for keys the wallet holds itself, such as the throwaway approver key
/// of a sign-in. The key lives only in memory.
class Ed25519DidKeySigner implements TrustTaskSigner {
  Ed25519DidKeySigner._(this._keyPair, this.did, this.verificationMethod);

  /// Creates a signer for a freshly generated Ed25519 key.
  factory Ed25519DidKeySigner.generate() {
    final (keyPair, _) = Ed25519KeyPair.generate();
    return Ed25519DidKeySigner._fromKeyPair(keyPair);
  }

  /// Creates a signer from a 32-byte Ed25519 seed.
  factory Ed25519DidKeySigner.fromSeed(Uint8List seed) {
    return Ed25519DidKeySigner._fromKeyPair(Ed25519KeyPair.fromSeed(seed));
  }

  factory Ed25519DidKeySigner._fromKeyPair(Ed25519KeyPair keyPair) {
    final multikey = toMultiBase(
      toMultikey(keyPair.publicKey.bytes, KeyType.ed25519),
    );
    final did = 'did:key:$multikey';
    return Ed25519DidKeySigner._(keyPair, did, '$did#$multikey');
  }

  final Ed25519KeyPair _keyPair;

  /// The key pair, for DIDComm key agreement as this DID.
  Ed25519KeyPair get keyPair => _keyPair;

  /// The 32-byte seed, to store the key and rebuild it with
  /// [Ed25519DidKeySigner.fromSeed]. Keep it in secure storage only.
  Uint8List get seed => _keyPair.getSeed();

  @override
  final String did;

  @override
  final String verificationMethod;

  @override
  Future<Uint8List> sign(Uint8List data) =>
      _keyPair.sign(data, signatureScheme: SignatureScheme.ed25519);
}
