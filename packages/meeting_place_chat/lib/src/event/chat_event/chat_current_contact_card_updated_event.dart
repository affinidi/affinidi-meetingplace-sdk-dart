part of 'chat_event.dart';

/// Emitted when the local identity's contact card is refreshed during an
/// active chat session.
///
/// This event signals that the SDK should re-evaluate whether a profile
/// update proposal should be sent to the other party based on the latest
/// contact card snapshot.
final class ChatCurrentContactCardUpdatedEvent extends ChatEvent {
  /// Creates a [ChatCurrentContactCardUpdatedEvent].
  ///
  /// The [contactCard] may be `null` if the identity no longer has a card
  /// associated with it.
  const ChatCurrentContactCardUpdatedEvent({required this.contactCard});

  /// The refreshed contact card for the signing identity, or `null` if
  /// the identity's card is no longer available.
  final ContactCard? contactCard;
}
