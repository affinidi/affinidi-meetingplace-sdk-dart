import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/trust_task_signer.dart';

/// The keys of a persona its VTA holds, borrowed for this session so DIDComm
/// can sign in, seal and unseal as the persona.
///
/// A VTA persona has an Ed25519 key it signs with and a separate X25519 key
/// it agrees keys with, which `ssi` cannot hold: it only agrees keys with an
/// X25519 key derived from an Ed25519 one. This manager holds both in memory
/// and is never written anywhere. Drop it with [forget] when the session
/// ends; the VTA lends the keys again next time.
///
/// Remove once `ssi` holds separate X25519 keys.
class PersonaDidManager extends DidManager {
  PersonaDidManager._(this._document, this._signing, this._keyAgreement)
    : super(
        store: InMemoryDidStore(),
        wallet: PersistentWallet(InMemoryKeyStore()),
      );

  /// Holds [signingSeed] and [keyAgreementKey] as the persona [document]
  /// names them: its first `authentication` key and its first
  /// `keyAgreement` key.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with an `invalidDocument` code when
  /// [document] names no such key, a key is not 32 bytes, or either key is
  /// not the one [document] states, so a wrong or swapped key is never used.
  static Future<PersonaDidManager> borrow({
    required DidDocument document,
    required Uint8List signingSeed,
    required Uint8List keyAgreementKey,
  }) async {
    final signingMethod = document.authentication.firstOrNull;
    final keyAgreementMethod = document.keyAgreement.firstOrNull;
    if (signingMethod == null || keyAgreementMethod == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'persona names no signing or key agreement key',
      );
    }
    if (signingSeed.length != _keyLength ||
        keyAgreementKey.length != _keyLength) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'persona key is not $_keyLength bytes',
      );
    }

    final signingId = _absoluteId(signingMethod, document.id);
    final keyAgreementId = _absoluteId(keyAgreementMethod, document.id);
    final signing = Ed25519KeyPair.fromSeed(
      Uint8List.fromList(signingSeed),
      id: signingId,
    );
    final keyAgreement = _X25519KeyPair(
      Uint8List.fromList(keyAgreementKey),
      keyAgreementId,
    );
    if (!_isKey(signingMethod, _ed25519Prefix, signing.publicKey.bytes) ||
        !_isKey(keyAgreementMethod, _x25519Prefix, keyAgreement.publicBytes)) {
      keyAgreement.forget();
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'persona key does not match its DID document',
      );
    }

    final manager = PersonaDidManager._(document, signing, keyAgreement);
    for (final (id, method) in [
      (signingId, signingMethod),
      (keyAgreementId, keyAgreementMethod),
    ]) {
      await manager.store.setMapping(id, id);
      if (method.id != id) await manager.store.setMapping(method.id, id);
    }
    await manager.store.addAuthentication(signingId);
    await manager.store.addAssertionMethod(signingId);
    await manager.store.addKeyAgreement(keyAgreementId);
    await manager.init();
    return manager;
  }

  static const _keyLength = 32;

  /// Multicodec prefixes of an Ed25519 and an X25519 public key.
  static const _ed25519Prefix = [0xed, 0x01];
  static const _x25519Prefix = [0xec, 0x01];

  final DidDocument _document;
  final Ed25519KeyPair _signing;
  final _X25519KeyPair _keyAgreement;
  bool _isForgotten = false;

  /// DID of the persona.
  String get did => _document.id;

  /// The persona's resolved DID document, as it is published.
  @override
  Future<DidDocument> getDidDocument() async => _document;

  @override
  Future<String> buildVerificationMethodId(PublicKey publicKey) async =>
      publicKey.id;

  @override
  Future<KeyPair> getKeyPair(String walletKeyId) async {
    if (_isForgotten) throw StateError('persona keys forgotten');
    if (walletKeyId == _signing.id) return _signing;
    if (walletKeyId == _keyAgreement.id) return _keyAgreement;
    throw StateError('not a persona key');
  }

  /// Signs as the persona with its lent signing key, for documents the VTA
  /// cannot sign because they name their signer other than as `issuer`,
  /// such as a vetting card's `publisher`.
  TrustTaskSigner get signer => _PersonaSigner(this);

  /// Zero-fills the key agreement key and refuses any key from now on.
  ///
  /// Best effort: Dart cannot wipe copies the runtime or `ssi` made, such as
  /// the signing key inside [Ed25519KeyPair]. Dropping the manager is what
  /// lets them go.
  void forget() {
    _isForgotten = true;
    _keyAgreement.forget();
  }

  static String _absoluteId(VerificationMethod method, String did) =>
      method.id.startsWith('#') ? '$did${method.id}' : method.id;

  static bool _isKey(
    VerificationMethod method,
    List<int> prefix,
    List<int> publicKey,
  ) {
    final Uint8List multikey;
    try {
      multikey = method.asMultiKey();
    } on Object {
      return false;
    }
    if (multikey.length != prefix.length + publicKey.length) return false;
    for (var i = 0; i < multikey.length; i++) {
      final expected = i < prefix.length
          ? prefix[i]
          : publicKey[i - prefix.length];
      if (multikey[i] != expected) return false;
    }
    return true;
  }
}

/// A separate X25519 key, which only agrees keys.
///
/// Its public key is typed [KeyType.ed25519]: `didcomm` names the X25519
/// curve that way (`KeyTypeExtension.asEncryptionCapableCurve`) and has no
/// case for [KeyType.x25519]. Only the type is read there; the bytes are
/// X25519.
class _X25519KeyPair extends KeyPair {
  _X25519KeyPair(this._privateKey, this.id)
    : publicBytes = x25519.X25519(_privateKey, x25519.basePoint);

  final Uint8List _privateKey;

  /// The X25519 public key.
  final Uint8List publicBytes;

  @override
  final String id;

  @override
  PublicKey get publicKey => PublicKey(id, publicBytes, KeyType.ed25519);

  @override
  SignatureScheme get defaultSignatureScheme => SignatureScheme.ed25519;

  @override
  Future<Uint8List> computeEcdhSecret(Uint8List publicKey) async =>
      x25519.X25519(_privateKey, publicKey);

  @override
  Future<Uint8List> internalSign(
    Uint8List data,
    SignatureScheme signatureScheme,
  ) => throw UnsupportedError('a key agreement key does not sign');

  @override
  Future<bool> internalVerify(
    Uint8List data,
    Uint8List signature,
    SignatureScheme signatureScheme,
  ) => throw UnsupportedError('a key agreement key does not verify');

  @override
  Future<Uint8List> encrypt(Uint8List data, {Uint8List? publicKey}) =>
      throw UnsupportedError('a key agreement key does not encrypt');

  @override
  Future<Uint8List> decrypt(Uint8List data, {Uint8List? publicKey}) =>
      throw UnsupportedError('a key agreement key does not decrypt');

  void forget() => _privateKey.fillRange(0, _privateKey.length, 0);
}

class _PersonaSigner implements TrustTaskSigner {
  _PersonaSigner(this._manager);

  final PersonaDidManager _manager;

  @override
  String get did => _manager.did;

  @override
  String get verificationMethod => _manager._signing.id;

  @override
  Future<Uint8List> sign(Uint8List data) {
    if (_manager._isForgotten) throw StateError('persona keys forgotten');
    return _manager._signing.sign(
      data,
      signatureScheme: SignatureScheme.ed25519,
    );
  }
}
