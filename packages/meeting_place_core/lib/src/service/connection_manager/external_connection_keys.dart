import 'dart:typed_data';

import 'package:ssi/ssi.dart';

/// A key held outside this device, such as on the member's VTA.
class ExternalKey {
  /// Creates an [ExternalKey].
  const ExternalKey({required this.keyId, required this.publicKey});

  /// The holder's reference to the key. Not a secret.
  final String keyId;

  /// The public key: 32 bytes for Ed25519, 33 compressed bytes for P-256.
  final Uint8List publicKey;
}

/// The keys of one permanent channel DID, held outside this device.
class ExternalDidKeys {
  /// Creates [ExternalDidKeys].
  const ExternalDidKeys({required this.signing, required this.agreement});

  /// An Ed25519 key, the DID's only assertion method. It never leaves its
  /// holder: credentials are signed there.
  final ExternalKey signing;

  /// A P-256 key, the DID's authentication and key agreement method. Its
  /// holder lends it to this device when DIDComm needs it.
  final ExternalKey agreement;
}

/// Keys held outside this device for permanent channel DIDs, so this device
/// keeps only references to them.
///
/// A permanent channel DID made while these keys are configured carries two
/// keys: an Ed25519 key, its only assertion method, that signs credentials
/// where it is held; and a P-256 key, for authentication and key agreement,
/// that is lent to this device when it signs in, seals or unseals.
/// P-256 because the parties and mediators Meeting Place talks to agree
/// keys on that curve.
abstract interface class ExternalConnectionKeys {
  /// Creates the keys of the new permanent channel DID [did], and remembers
  /// them for [findKeys]. Returns null when there is nowhere to hold them,
  /// such as no linked VTA: [did] then keeps all its keys on the device.
  ///
  /// Throws when keys are held externally but these cannot be created, so
  /// the DID is never quietly made with device keys.
  Future<ExternalDidKeys?> createKeys(String did);

  /// The keys created for [did], or null when [did] has none.
  Future<ExternalDidKeys?> findKeys(String did);

  /// Returns [document] with an `eddsa-jcs-2022` proof made by the key
  /// [keyId], as the DID that [document] names as its `issuer`.
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String keyId,
  });

  /// Lends the 32-byte P-256 private key [keyId].
  ///
  /// The secret must stay in memory: never write or log it. An
  /// implementation may hold it for the session so each message does not
  /// ask again.
  Future<Uint8List> lendSecret(String keyId);
}

/// A [Wallet] that answers for [ExternalConnectionKeys] alongside a device
/// wallet: it knows the public half of each external key, borrows the
/// agreement key when asked for its key pair, and forwards everything else
/// to the device wallet.
///
/// An external signing key cannot sign raw bytes: credentials are signed
/// through [signDocument].
class ExternalKeyWallet implements Wallet {
  /// Creates an [ExternalKeyWallet] over [device].
  ExternalKeyWallet(this.device, this.externalKeys);

  /// Wallet ids of external keys start with this, to never collide with a
  /// device key.
  static const keyIdPrefix = 'external:';

  /// The device wallet.
  final Wallet device;

  /// Where the external keys are held.
  final ExternalConnectionKeys externalKeys;

  final Map<String, ExternalKey> _signingKeys = {};
  final Map<String, ExternalKey> _agreementKeys = {};

  /// Makes the signing key [key] known, and returns its wallet key id.
  String addSigningKey(ExternalKey key) =>
      _add(_signingKeys, key, kind: 'signing');

  /// Makes the agreement key [key] known, and returns its wallet key id.
  String addAgreementKey(ExternalKey key) =>
      _add(_agreementKeys, key, kind: 'agreement');

  /// Whether [walletKeyId] names an external key.
  bool isExternal(String walletKeyId) => _isSigning(walletKeyId) ||
      _isAgreement(walletKeyId);

  /// Returns [document] signed by the external signing key [walletKeyId],
  /// as the DID that [document] names as its `issuer`.
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String walletKeyId,
  }) {
    final key = _signingKeys[walletKeyId];
    if (key == null) throw ArgumentError.value(walletKeyId, 'walletKeyId');
    return externalKeys.signDocument(document, keyId: key.keyId);
  }

  String _add(
    Map<String, ExternalKey> keys,
    ExternalKey key, {
    required String kind,
  }) {
    final walletKeyId = '$keyIdPrefix$kind:${key.keyId}';
    keys[walletKeyId] = key;
    return walletKeyId;
  }

  bool _isSigning(String walletKeyId) => _signingKeys.containsKey(walletKeyId);

  bool _isAgreement(String walletKeyId) =>
      _agreementKeys.containsKey(walletKeyId);

  /// The agreement key [walletKeyId], borrowed from where it is held.
  ///
  /// Throws [StateError] when the lent key is not the one the DID
  /// publishes, so a wrong key is never used.
  Future<KeyPair> _borrow(String walletKeyId) async {
    final key = _agreementKeys[walletKeyId]!;
    final secret = await externalKeys.lendSecret(key.keyId);
    final KeyPair keyPair;
    try {
      keyPair = P256KeyPair.fromPrivateKey(secret, id: walletKeyId);
    } finally {
      secret.fillRange(0, secret.length, 0);
    }
    if (!_isSame(keyPair.publicKey.bytes, key.publicKey)) {
      throw StateError('lent key does not match the DID');
    }
    return keyPair;
  }

  static bool _isSame(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Never _noRawSigning() => throw UnsupportedError(
    'An external signing key signs documents only, through signDocument.',
  );

  @override
  Future<PublicKey> getPublicKey(String keyId) async {
    if (_signingKeys[keyId] case final key?) {
      return PublicKey(keyId, key.publicKey, KeyType.ed25519);
    }
    if (_agreementKeys[keyId] case final key?) {
      return PublicKey(keyId, key.publicKey, KeyType.p256);
    }
    return device.getPublicKey(keyId);
  }

  @override
  Future<List<SignatureScheme>> getSupportedSignatureSchemes(String keyId) {
    if (_isSigning(keyId)) return Future.value(const [SignatureScheme.ed25519]);
    if (_isAgreement(keyId)) {
      return Future.value(const [SignatureScheme.ecdsa_p256_sha256]);
    }
    return device.getSupportedSignatureSchemes(keyId);
  }

  @override
  Future<Uint8List> sign(
    Uint8List data, {
    required String keyId,
    SignatureScheme? signatureScheme,
  }) async {
    if (_isSigning(keyId)) _noRawSigning();
    if (_isAgreement(keyId)) {
      return (await _borrow(
        keyId,
      )).sign(data, signatureScheme: signatureScheme);
    }
    return device.sign(data, keyId: keyId, signatureScheme: signatureScheme);
  }

  @override
  Future<bool> verify(
    Uint8List data, {
    required Uint8List signature,
    required String keyId,
    SignatureScheme? signatureScheme,
  }) async {
    if (_isSigning(keyId)) _noRawSigning();
    if (_isAgreement(keyId)) {
      return (await _borrow(
        keyId,
      )).verify(data, signature, signatureScheme: signatureScheme);
    }
    return device.verify(
      data,
      signature: signature,
      keyId: keyId,
      signatureScheme: signatureScheme,
    );
  }

  /// Returns the borrowed key pair of an agreement key: [DidManager] asks a
  /// wallet that is not a [PersistentWallet] for key pairs this way.
  @override
  Future<KeyPair> generateKey({String? keyId, KeyType? keyType}) {
    if (keyId != null && _isSigning(keyId)) _noRawSigning();
    if (keyId != null && _isAgreement(keyId)) return _borrow(keyId);
    return device.generateKey(keyId: keyId, keyType: keyType);
  }

  @override
  Future<Uint8List> encrypt(
    Uint8List data, {
    required String keyId,
    Uint8List? publicKey,
  }) async {
    if (_isSigning(keyId)) _noRawSigning();
    if (_isAgreement(keyId)) {
      return (await _borrow(keyId)).encrypt(data, publicKey: publicKey);
    }
    return device.encrypt(data, keyId: keyId, publicKey: publicKey);
  }

  @override
  Future<Uint8List> decrypt(
    Uint8List data, {
    required String keyId,
    Uint8List? publicKey,
  }) async {
    if (_isSigning(keyId)) _noRawSigning();
    if (_isAgreement(keyId)) {
      return (await _borrow(keyId)).decrypt(data, publicKey: publicKey);
    }
    return device.decrypt(data, keyId: keyId, publicKey: publicKey);
  }
}
