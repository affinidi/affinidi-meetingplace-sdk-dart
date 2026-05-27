part of 'chat_event.dart';

/// The group membership list was updated (members added or status changed).
final class ChatGroupMembersUpdatedEvent extends ChatEvent {
  const ChatGroupMembersUpdatedEvent({required this.groupDid});

  /// DID of the group whose membership changed.
  final String groupDid;
}
