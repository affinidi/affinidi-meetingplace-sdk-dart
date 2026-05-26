/// Transport-neutral identifiers for chat events. Used as dispatch keys for
/// [ChatEventHandler]s. Each transport (Matrix, DIDComm, ...) is responsible
/// for translating its native event type into one of these values before
/// invoking a chat-layer handler.
abstract final class ChatEventTypes {
  static const memberJoined = 'chat.memberJoined';
  static const memberLeft = 'chat.memberLeft';
  static const groupDeletion = 'chat.groupDeletion';
  static const groupDetailsUpdate = 'chat.groupDetailsUpdate';
  static const contactDetailsUpdate = 'chat.contactDetailsUpdate';
  static const chatEffect = 'chat.effect';
}
