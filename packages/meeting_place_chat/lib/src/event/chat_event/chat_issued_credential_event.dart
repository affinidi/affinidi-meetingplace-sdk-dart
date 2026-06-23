part of 'chat_event.dart';

/// An issued-credential event was received from the remote party.
final class ChatIssuedCredentialEvent extends ChatEvent {
  const ChatIssuedCredentialEvent({
    this.senderDid,
    required this.body,
    required this.createdTime,
    required this.attachments,
  });

  /// DID of the sender, if present.
  final String? senderDid;

  /// Raw protocol body payload.
  final Map<String, dynamic> body;

  /// Timestamp when the event was created.
  final DateTime createdTime;

  /// Attachments included with the issued credential.
  final List<CoreAttachment> attachments;
}
