part of 'chat_event.dart';

/// The other party requested permission to update their profile details.
final class ChatProfileRequestEvent extends ChatEvent {
  const ChatProfileRequestEvent({
    required this.senderDid,
    required this.profileHash,
  });

  /// DID of the party requesting the profile update.
  final String senderDid;

  /// The profile hash that was proposed.
  final String profileHash;
}
