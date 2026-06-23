part of 'chat_event.dart';

/// The group associated with this chat was deleted.
final class ChatGroupDeletedEvent extends ChatEvent {
  const ChatGroupDeletedEvent({required this.groupDid});

  /// DID of the group that was deleted.
  final String groupDid;
}
