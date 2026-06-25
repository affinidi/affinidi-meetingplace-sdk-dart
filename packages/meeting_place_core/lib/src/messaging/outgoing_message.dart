import 'package:didcomm/didcomm.dart';

import '../../meeting_place_core.dart' show MeetingPlaceCoreSDK;

import '../call/call_media_type.dart';
import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// A message that can be sent through [MeetingPlaceCoreSDK.sendMessage],
/// regardless of the underlying transport.
///
/// Concrete subclasses describe a specific use case (chat text, reaction,
/// read receipt, typing notification, connection request, …) and extend one
/// of the two transport-specific base classes [MatrixOutgoingMessage] or
/// [DidCommOutgoingMessage]. CoreSDK routes by the transport base class.
abstract class OutgoingMessage {
  const OutgoingMessage({required this.senderDid});

  /// DID of the sender. Used by CoreSDK to resolve a `DidManager` for the
  /// outgoing operation.
  final String senderDid;
}

/// An [OutgoingMessage] routed through the Matrix transport.
///
/// Carries everything `MatrixService.sendRoomEvent` needs: event [type]
/// (e.g. a chat protocol URI, `m.read`, `m.reaction`, `m.room.redaction`,
/// `m.typing`) and JSON [content]. The target room is resolved from the
/// channel owned by [senderDid].
abstract class MatrixOutgoingMessage extends OutgoingMessage {
  const MatrixOutgoingMessage({
    required super.senderDid,
    required this.type,
    required this.content,
    this.notification,
  });

  /// Matrix event type (e.g. `m.read`, `m.reaction`, `m.room.redaction`,
  /// `m.typing`).
  final String type;

  /// JSON content of the Matrix event. Must be serializable to `Map<String,
  final Map<String, dynamic> content;

  /// When set, the core SDK fires a fire-and-forget control-plane channel
  /// notification after the room event is delivered to the homeserver.
  final ChannelNotification? notification;
}

/// Parameters required to dispatch a control-plane channel notification for
/// a [MatrixOutgoingMessage]. Either an individual peer or all members of a
/// group are notified, depending on the concrete subtype.
sealed class ChannelNotification {
  const ChannelNotification({required this.type});

  /// Notification type passed to the underlying control-plane command (e.g.
  /// `chat-activity`, `chat-message`).
  final String type;
}

/// Notifies a single peer via their `Channel.otherPartyNotificationToken`.
class IndividualChannelNotification extends ChannelNotification {
  const IndividualChannelNotification({
    required this.recipientDid,
    required super.type,
    this.mediaType,
  });

  /// DID of the recipient whose `Channel.otherPartyNotificationToken` is
  /// used to address the notification.
  final String recipientDid;

  /// Optional media type for a `call-invite` notification, so the recipient's
  /// incoming-call UI can render the correct type without a follow-up fetch.
  final CallMediaType? mediaType;
}

/// Notifies all members of a group chat via the control-plane group-notify
/// endpoint.
class GroupChannelNotification extends ChannelNotification {
  const GroupChannelNotification({
    required this.offerLink,
    required this.groupDid,
    required super.type,
  });

  /// The Offer link associated with the group chat.
  final String offerLink;

  /// The channel DID for the group chat.
  final String groupDid;
}

/// An [OutgoingMessage] routed through the DIDComm transport.
class DidCommOutgoingMessage extends OutgoingMessage {
  const DidCommOutgoingMessage({
    required super.senderDid,
    required this.recipientDid,
    required this.payload,
    this.mediatorDid,
    this.notifyChannelType,
    this.ephemeral = false,
    this.forwardExpiryInSeconds,
  });

  final String recipientDid;
  final PlainTextMessage payload;
  final String? mediatorDid;
  final String? notifyChannelType;
  final bool ephemeral;
  final int? forwardExpiryInSeconds;
}
