part of 'chat_event.dart';

/// A member left (deregistered from) the group.
final class ChatMemberDeregisteredEvent extends ChatEvent {
  const ChatMemberDeregisteredEvent({
    required this.groupDid,
    required this.memberDid,
  });

  /// DID of the group the member belonged to.
  final String groupDid;

  /// DID of the member that left.
  final String memberDid;
}
