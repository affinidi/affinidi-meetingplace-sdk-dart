import '../../meeting_place_chat.dart' show ChatEventHandler;
import 'chat_event_handler.dart' show ChatEventHandler;
import 'event.dart' show ChatEventHandler;

/// Transport-neutral identifiers for chat events. Used as dispatch keys for
/// [ChatEventHandler]s. Each transport is responsible
/// for translating its native event type into one of these values before
/// invoking a chat-layer handler.
abstract final class ChatEventTypes {
  /// A member joined the chat's group.
  static const memberJoined = 'chat.memberJoined';

  /// A member left the chat's group.
  static const memberLeft = 'chat.memberLeft';

  /// The chat's group was deleted.
  static const groupDeletion = 'chat.groupDeletion';

  /// The chat's group details were updated.
  static const groupDetailsUpdate = 'chat.groupDetailsUpdate';

  /// The other party's contact details were updated.
  static const contactDetailsUpdate = 'chat.contactDetailsUpdate';

  /// A visual chat effect was received.
  static const chatEffect = 'chat.effect';
}
