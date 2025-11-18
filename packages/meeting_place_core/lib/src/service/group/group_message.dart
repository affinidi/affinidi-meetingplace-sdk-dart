import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:proxy_recrypt/proxy_recrypt.dart' as recrypt;

import '../../../meeting_place_core.dart';

class EncryptedGroupMessage {
  EncryptedGroupMessage({
    required this.ciphertextBytes,
    required this.capsule,
    required this.initializationVector,
    required this.authenticationTag,
  });

  final Uint8List ciphertextBytes;
  final recrypt.Capsule capsule;
  final Uint8List initializationVector;
  final Uint8List authenticationTag;
}

class GroupMessage {
  static EncryptedGroupMessage encrypt(
    PlainTextMessage message, {
    required Uint8List publicKeyBytes,
  }) {
    final groupPublicKey = recrypt.PublicKey.fromBase64(
      base64.encode(publicKeyBytes),
    );
    final encapsulateResult = recrypt.Recrypt().encapsulate(groupPublicKey);

    final capsule = encapsulateResult['capsule'] as recrypt.Capsule;
    final symmetricKeyBytes = encapsulateResult['symmetricKey'] as Uint8List;

    final encryptionResult =
        _encryptMessage(message, symmetricKeyBytes: symmetricKeyBytes);

    final encrypted = EncryptedGroupMessage(
      capsule: capsule,
      ciphertextBytes: encryptionResult.data,
      initializationVector: encryptionResult.initializationVector!,
      authenticationTag: encryptionResult.authenticationTag!,
    );
    return encrypted;
  }

  static PlainTextMessage decrypt(
    PlainTextMessage message, {
    required Uint8List privateKeyBytes,
  }) {
    final ciphertext = base64.decode(message.body!['ciphertext'] as String);
    final capsule = _getCapsuleFromMessage(message);
    final initializationVector = _getIVFromMessage(message);

    final privateKey = recrypt.PrivateKey.fromBase64(
      base64.encode(privateKeyBytes),
    );

    final symmetricKeyBytes =
        recrypt.Recrypt().decapsulate(capsule, privateKey);

    final authenticationTagBytes =
        base64.decode(message.body!['authenticationTag'] as String);

    final decryptedBytes = _decryptCiphertext(
      ciphertext,
      symmetricKeyBytes: symmetricKeyBytes,
      initializationVector: initializationVector,
      authenticationTag: authenticationTagBytes,
    );

    final plainTextMessage = PlainTextMessage.fromJson(
      jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>,
    );

    return plainTextMessage;
  }

  static recrypt.Capsule _getCapsuleFromMessage(PlainTextMessage message) {
    return recrypt.Capsule.fromBase64(message.body!['preCapsule'] as String);
  }

  static Uint8List _getIVFromMessage(PlainTextMessage message) {
    return base64.decode(message.body!['iv'] as String);
  }

  static Uint8List _decryptCiphertext(
    Uint8List ciphertext, {
    required Uint8List symmetricKeyBytes,
    required Uint8List initializationVector,
    required Uint8List authenticationTag,
  }) {
    final encrypter = _createEncrypter(symmetricKeyBytes);
    final decrypted = encrypter.decrypt(ck.EncryptionResult(
      ciphertext,
      initializationVector: initializationVector,
      authenticationTag: authenticationTag,
    ));
    return decrypted;
  }

  static ck.EncryptionResult _encryptMessage(
    PlainTextMessage message, {
    required Uint8List symmetricKeyBytes,
  }) {
    final encrypter = _createEncrypter(symmetricKeyBytes);
    return encrypter.encrypt(
      utf8.encode(jsonEncode(message.toJson())),
    );
  }

  static ck.Encrypter _createEncrypter(Uint8List symmetricKeyBytes) {
    final symmetricKey = ck.SymmetricKey(keyValue: symmetricKeyBytes);
    return symmetricKey.createEncrypter(ck.algorithms.encryption.aes.gcm);
  }
}
