part of 'chat_event.dart';

/// The other party proposed a new profile hash for comparison.
final class ChatProfileHashEvent extends ChatEvent {
  const ChatProfileHashEvent({
    required this.senderDid,
    required this.profileHash,
  });

  /// DID of the party proposing the profile hash.
  final String senderDid;

  /// The proposed profile hash value.
  final String profileHash;
}
