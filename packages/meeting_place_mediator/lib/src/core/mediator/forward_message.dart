import 'package:didcomm/didcomm.dart' as didcomm;

/// [ForwardMessage] is used to forward messages by their IDs to the recipient.
///
/// **Parameters:**
/// - [id]: Unique identifier for the message ("id" field in DIDComm spec).
/// - [to]: List of recipient DIDs.
/// - [attachments]: List of attachments.
/// - [next]: The DID of the next recipient to which the attached message should be forwarded.
/// - [expiresTime]: Message expiration time as a UTC timestamp ("expires_time" field in DIDComm spec).
/// - [from]: Sender's DID.
class ForwardMessage extends didcomm.ForwardMessage {
  ForwardMessage({
    required super.id,
    required super.to,
    required super.attachments,
    required super.next,
    super.expiresTime,
    super.from,
    bool ephemeral = false,
  });
}
