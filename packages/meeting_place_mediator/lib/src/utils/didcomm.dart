import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../core/mediator/mediator_exception.dart';

/// Utility function to sign and encrypt a message for a specific recipient.
///
/// **Parameters**
/// - [message]: The [PlainTextMessage] that was delivered.
/// - [senderDidManager]: The DidManager instance used for authentication with the mediator
/// and contains the identity credentials needed for the session.
/// - [recipientDidDocument]: DID document that contains the recipient agent’s public keys,
/// service endpoints, and routing information required to securely receive, decrypt,
/// and respond to DIDComm messages.
Future<EncryptedMessage> signAndEncryptMessage(
  PlainTextMessage message, {
  required DidManager senderDidManager,
  required DidDocument recipientDidDocument,
}) async {
  final senderDidDocument = await senderDidManager.getDidDocument();
  final authenticationKeyId = senderDidDocument.authentication.first.id;

  final keyAgreements = senderDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [recipientDidDocument],
  );

  if (keyAgreements.isEmpty) {
    throw MediatorException.keyAgreementMismatch();
  }

  final signedMessage = await SignedMessage.pack(
    message,
    signer: await senderDidManager.getSigner(authenticationKeyId),
  );

  return EncryptedMessage.packWithAuthentication(
    signedMessage,
    didKeyId: keyAgreements.first,
    keyPair: await senderDidManager.getKeyPairByDidKeyId(keyAgreements.first),
    recipientDidDocuments: [recipientDidDocument],
  );
}

String uuid() => const Uuid().v4();
