import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

/// Utility function to sign and encrypt a message for a specific recipient
Future<EncryptedMessage> signAndEncryptMessage(
  PlainTextMessage message, {
  required DidManager senderDidManager,
  required DidDocument recipientDidDocument,
}) async {
  final senderDidDocument = await senderDidManager.getDidDocument();
  final authenticationKeyId = senderDidDocument.authentication.first.id;

  final keyAgreementKeyId = senderDidDocument
      .matchKeysInKeyAgreement(otherDidDocuments: [recipientDidDocument])
      .first;

  final signedMessage = await SignedMessage.pack(
    message,
    signer: await senderDidManager.getSigner(authenticationKeyId),
  );

  return EncryptedMessage.packWithAuthentication(
    signedMessage,
    didKeyId: keyAgreementKeyId,
    keyPair: await senderDidManager.getKeyPairByDidKeyId(keyAgreementKeyId),
    recipientDidDocuments: [recipientDidDocument],
  );
}

String uuid() => const Uuid().v4();
