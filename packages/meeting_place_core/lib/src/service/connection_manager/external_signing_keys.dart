import 'dart:typed_data';

import 'package:ssi/ssi.dart';

/// An Ed25519 key held outside this device, such as on the member's VTA,
/// that signs credentials as a permanent channel DID.
class ExternalSigningKey {
  /// Creates an [ExternalSigningKey].
  const ExternalSigningKey({required this.keyId, required this.publicKey});

  /// The holder's reference to the key. Not a secret.
  final String keyId;

  /// The 32-byte Ed25519 public key.
  final Uint8List publicKey;
}

/// Keys held outside this device that sign credentials as permanent channel
/// DIDs, so their private halves never reach the phone.
///
/// A permanent channel DID made while these keys are configured carries two
/// keys: the device's own, for authentication and key agreement (DIDComm
/// and the mediator stay on the device), and an external Ed25519 key, its
/// only assertion method, for credentials.
abstract interface class ExternalSigningKeys {
  /// Creates a key for the new permanent channel DID [did], and remembers it
  /// for [findKey]. Returns null when there is nowhere to hold one, such as
  /// no linked VTA: [did] then keeps all its keys on the device.
  ///
  /// Throws when keys are held externally but this one cannot be created,
  /// so the DID is never quietly made with a device signing key.
  Future<ExternalSigningKey?> createKey(String did);

  /// The key created for [did], or null when [did] has none.
  Future<ExternalSigningKey?> findKey(String did);

  /// Returns [document] with an `eddsa-jcs-2022` proof made by the key
  /// [keyId], as the DID that [document] names as its `issuer`.
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String keyId,
  });
}

/// A [Wallet] that answers for [ExternalSigningKeys] alongside a device
/// wallet: it knows the public half of each external key, and forwards
/// everything else to the device wallet.
///
/// An external key cannot sign raw bytes: credentials are signed through
/// [signDocument].
class ExternalKeyWallet implements Wallet {
  /// Creates an [ExternalKeyWallet] over [device].
  ExternalKeyWallet(this.device, this.externalKeys);

  /// Wallet ids of external keys start with this, to never collide with a
  /// device key.
  static const keyIdPrefix = 'external:';

  /// The device wallet.
  final Wallet device;

  /// Where the external keys are held.
  final ExternalSigningKeys externalKeys;

  final Map<String, ExternalSigningKey> _keys = {};

  /// Makes [key] known, and returns its wallet key id.
  String add(ExternalSigningKey key) {
    final walletKeyId = '$keyIdPrefix${key.keyId}';
    _keys[walletKeyId] = key;
    return walletKeyId;
  }

  /// Whether [walletKeyId] names an external key.
  bool isExternal(String walletKeyId) => _keys.containsKey(walletKeyId);

  /// Returns [document] signed by the external key [walletKeyId], as the
  /// DID that [document] names as its `issuer`.
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String walletKeyId,
  }) => externalKeys.signDocument(document, keyId: _key(walletKeyId).keyId);

  ExternalSigningKey _key(String walletKeyId) {
    final key = _keys[walletKeyId];
    if (key == null) throw ArgumentError.value(walletKeyId, 'walletKeyId');
    return key;
  }

  Never _noRawSigning() => throw UnsupportedError(
    'An external key signs documents only, through signDocument.',
  );

  @override
  Future<PublicKey> getPublicKey(String keyId) async {
    if (!isExternal(keyId)) return device.getPublicKey(keyId);
    return PublicKey(keyId, _key(keyId).publicKey, KeyType.ed25519);
  }

  @override
  Future<List<SignatureScheme>> getSupportedSignatureSchemes(String keyId) =>
      isExternal(keyId)
      ? Future.value(const [SignatureScheme.ed25519])
      : device.getSupportedSignatureSchemes(keyId);

  @override
  Future<Uint8List> sign(
    Uint8List data, {
    required String keyId,
    SignatureScheme? signatureScheme,
  }) {
    if (isExternal(keyId)) _noRawSigning();
    return device.sign(data, keyId: keyId, signatureScheme: signatureScheme);
  }

  @override
  Future<bool> verify(
    Uint8List data, {
    required Uint8List signature,
    required String keyId,
    SignatureScheme? signatureScheme,
  }) {
    if (isExternal(keyId)) _noRawSigning();
    return device.verify(
      data,
      signature: signature,
      keyId: keyId,
      signatureScheme: signatureScheme,
    );
  }

  @override
  Future<KeyPair> generateKey({String? keyId, KeyType? keyType}) {
    if (keyId != null && isExternal(keyId)) _noRawSigning();
    return device.generateKey(keyId: keyId, keyType: keyType);
  }

  @override
  Future<Uint8List> encrypt(
    Uint8List data, {
    required String keyId,
    Uint8List? publicKey,
  }) {
    if (isExternal(keyId)) _noRawSigning();
    return device.encrypt(data, keyId: keyId, publicKey: publicKey);
  }

  @override
  Future<Uint8List> decrypt(
    Uint8List data, {
    required String keyId,
    Uint8List? publicKey,
  }) {
    if (isExternal(keyId)) _noRawSigning();
    return device.decrypt(data, keyId: keyId, publicKey: publicKey);
  }
}
