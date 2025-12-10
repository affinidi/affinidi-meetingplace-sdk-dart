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
  chatActivity('https://affinidi.io/mpx/chat-sdk/activity'),

  /// Represents a hash of the user's profile (vCard) for identity validation.
  chatAliasProfileHash('https://affinidi.io/mpx/chat-sdk/alias-profile-hash'),

  /// Represents a request to validate or update a user's alias profile.
  chatAliasProfileRequest(
    'https://affinidi.io/mpx/chat-sdk/alias-profile-request',
  ),

  /// Represents verifiable presentations of chat attachments.
  chatAttachmentsVerifiablePresentation(
    'https://affinidi.io/mpx/chat-sdk/attachments-verifiable-presentation',
  ),

  /// Represents an update to contact details (e.g., vCard information).
  chatContactDetailsUpdate(
    'https://affinidi.io/mpx/chat-sdk/contact-details-update',
  ),

  /// Represents a "delivered" acknowledgement for received messages.
  chatDelivered('https://affinidi.io/mpx/chat-sdk/delivered'),

  /// Represents a visual or animated effect sent in chat.
  chatEffect('https://affinidi.io/mpx/chat-sdk/effect'),

  /// Represents an update to group details (e.g., membership changes).
  chatGroupDetailsUpdate(
    'https://affinidi.io/mpx/chat-sdk/group-details-update',
  ),

  /// Represents a plain chat message.
  chatMessage('https://affinidi.io/mpx/chat-sdk/message'),

  /// Represents an online/offline presence signal.
  chatPresence('https://affinidi.io/mpx/chat-sdk/presence'),

  /// Represents a reaction (emoji or similar) to a chat message.
  chatReaction('https://affinidi.io/mpx/chat-sdk/reaction'),

  /// Represents a declined persona sharing.
  // TODO (Earl): remove this protocol once extension is merged
  chatDeclinedPersonaSharing(
      'https://affinidi.io/mpx/chat-sdk/declined-persona-sharing');

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
