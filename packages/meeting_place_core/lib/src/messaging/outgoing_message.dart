import 'package:didcomm/didcomm.dart';

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
/// Carries everything `MatrixService.sendRoomEvent` needs: target [roomId],
/// event [type] (e.g. a chat protocol URI, `m.read`, `m.reaction`,
/// `m.room.redaction`, `m.typing`), and JSON [content].
abstract class MatrixOutgoingMessage extends OutgoingMessage {
  const MatrixOutgoingMessage({
    required super.senderDid,
    required this.roomId,
    required this.type,
    required this.content,
    this.notification,
  });

  final String roomId;
  final String type;
  final Map<String, dynamic> content;

  /// When set, the core SDK fires a fire-and-forget control-plane channel
  /// notification after the room event is delivered to the homeserver.
  final ChannelNotification? notification;
}

/// Parameters required to dispatch a control-plane channel notification for
/// a [MatrixOutgoingMessage].
class ChannelNotification {
  const ChannelNotification({
    required this.recipientDid,
    required this.type,
  });

  /// DID of the recipient whose `Channel.otherPartyNotificationToken` is
  /// used to address the notification.
  final String recipientDid;

  /// Notification type passed to `NotifyChannelCommand` (e.g. `chat-activity`,
  /// `chat-message`).
  final String type;
}

/// An [OutgoingMessage] routed through the DIDComm transport.
abstract class DidCommOutgoingMessage extends OutgoingMessage {
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
