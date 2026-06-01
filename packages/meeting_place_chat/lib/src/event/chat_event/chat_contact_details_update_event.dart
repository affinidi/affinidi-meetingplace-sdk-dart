part of 'chat_event.dart';

/// A contact card belonging to the other party (or a group member) was
/// updated.
final class ChatContactDetailsUpdateEvent extends ChatEvent {
  const ChatContactDetailsUpdateEvent({
    required this.senderDid,
    required this.contactCard,
  });

  /// DID of the party whose contact card changed.
  final String senderDid;

  /// The updated contact card.
  final ContactCard contactCard;
}
