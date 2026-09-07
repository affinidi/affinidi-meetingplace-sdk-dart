import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

/// Parameters for `MeetingPlaceMediatorSDK.sendMessage` and
/// `MeetingPlaceMediatorSDK.queueMessage`.
class MediatorMessageRequest {
  const MediatorMessageRequest({
    required this.message,
    required this.senderDidManager,
    required this.recipientDidDocument,
    this.mediatorDid,
    this.next,
    this.ephemeral,
    this.forwardExpiryInSeconds,
  });

  /// The DIDComm message to send or queue.
  final PlainTextMessage message;

  /// The [DidManager] instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  final DidManager senderDidManager;

  /// DID document that contains the recipient agent's public keys, service
  /// endpoints, and routing information required to securely receive,
  /// decrypt, and respond to DIDComm messages.
  final DidDocument recipientDidDocument;

  /// Optional mediator DID to authenticate against. If not provided, the
  /// SDK instance's default mediator DID will be used.
  final String? mediatorDid;

  /// Optional forwarding target. Defaults to [recipientDidDocument]'s id
  /// when not provided.
  final String? next;

  /// Whether the message should be treated as ephemeral.
  final bool? ephemeral;

  /// Optional expiry, in seconds, for the forwarded message.
  final int? forwardExpiryInSeconds;
}
