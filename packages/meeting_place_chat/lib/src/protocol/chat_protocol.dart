import 'package:collection/collection.dart';

/// [ChatProtocol] defines the supported **DIDComm message types**
/// used by the chat system in the Meeting Place SDK.
///
/// Each enum value maps to a unique URI string that identifies the
/// protocol and specific action of the DIDComm message exchanged between
/// participants.
///
/// These protocols enable features such as presence, reactions,
/// profile updates, and message delivery acknowledgements.
enum ChatProtocol {
  /// Represents a "typing" or activity indicator.
  chatActivity(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/chat-activity',
  ),

  /// Represents a hash of the user's profile (contact card) for identity validation.
  chatAliasProfileHash(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/alias-profile-hash',
  ),

  /// Represents a request to validate or update a user's alias profile.
  chatAliasProfileRequest(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/alias-profile-request',
  ),

  /// Represents verifiable presentations of chat attachments.
  chatAttachmentsVerifiablePresentation(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/attachments-verifiable-presentation',
  ),

  /// Represents an update to contact details (e.g., contact card information).
  chatContactDetailsUpdate(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/contact-details-update',
  ),

  /// Represents a "delivered" acknowledgement for received messages.
  chatDelivered(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/delivered',
  ),

  /// Represents a visual or animated effect sent in chat.
  chatEffect(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/effect',
  ),

  /// Represents an update to group details (e.g., membership changes).
  chatGroupDetailsUpdate(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/group-details-update',
  ),

  /// Represents a plain chat message.
  chatMessage(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/message',
  ),

  /// Represents an online/offline presence signal.
  chatPresence(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/presence',
  ),

  /// Represents a reaction (emoji or similar) to a chat message.
  chatReaction(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/reaction',
  ),

  /// Represents a declined persona sharing.
  // TODO (Earl): remove this protocol once extension is merged
  chatDeclinedPersonaSharing(
    'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/declined-persona-sharing',
  );

  /// Creates a [ChatProtocol] instance with the given URI [value].
  const ChatProtocol(this.value);

  /// The URI string that uniquely identifies this chat protocol.
  final String value;

  /// Looks up a [ChatProtocol] by its URI [value].
  ///
  /// **Parameters:**
  /// - [value]: The URI string of the protocol.
  ///
  /// **Returns:**
  /// - The matching [ChatProtocol], or `null` if no match is found.
  static ChatProtocol? byValue(String value) {
    return ChatProtocol.values.firstWhereOrNull((e) => e.value == value);
  }
}
