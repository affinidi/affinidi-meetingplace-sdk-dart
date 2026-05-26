part of 'chat_event.dart';

/// A contact's details (profile card) were updated.
final class ChatContactDetailsUpdateEvent extends ChatEvent {
  const ChatContactDetailsUpdateEvent({
    required this.senderDid,
    required this.contactCard,
  });

  /// DID of the contact whose card was updated.
  final String senderDid;

  /// The updated contact card.
  final ContactCard contactCard;
}
