import 'package:didcomm/didcomm.dart';

import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// A message that can be sent through [MeetingPlaceCoreSDK.sendMessage],
/// regardless of the underlying transport.
abstract class OutgoingMessage {
  /// Creates an [OutgoingMessage].
  const OutgoingMessage({required this.senderDid});

  /// DID of the sender. Used by CoreSDK to resolve a `DidManager` for the
  /// outgoing operation.
  final String senderDid;
}

/// Parameters required to dispatch a control-plane channel notification.
///
/// Either an individual peer or all members of a group are notified,
/// depending on the concrete subtype.
sealed class ChannelNotification {
  /// Creates a [ChannelNotification].
  const ChannelNotification({required this.type});

  /// Notification type passed to the underlying control-plane command (e.g.
  /// `chat-activity`, `chat-message`).
  final String type;
}

/// Notifies a single peer via their `Channel.otherPartyNotificationToken`.
class IndividualChannelNotification extends ChannelNotification {
  /// Creates an [IndividualChannelNotification].
  const IndividualChannelNotification({
    required this.recipientDid,
    required super.type,
  });

  /// DID of the recipient whose `Channel.otherPartyNotificationToken` is
  /// used to address the notification.
  final String recipientDid;
}

/// Notifies all members of a group chat via the control-plane group-notify
/// endpoint.
class GroupChannelNotification extends ChannelNotification {
  /// Creates a [GroupChannelNotification].
  const GroupChannelNotification({
    required this.groupId,
    required super.type,
    this.memberDid,
  });

  /// The unique identifier of the group chat to notify.
  final String groupId;

  /// When set, notify only this single group member instead of all members.
  final String? memberDid;
}

/// An [OutgoingMessage] routed through the DIDComm transport.
class DidCommOutgoingMessage extends OutgoingMessage {
  /// Creates a [DidCommOutgoingMessage].
  const DidCommOutgoingMessage({
    required super.senderDid,
    required this.recipientDid,
    required this.payload,
    this.mediatorDid,
    this.notifyChannelType,
    this.ephemeral = false,
    this.forwardExpiryInSeconds,
  });

  /// DID of the intended recipient.
  final String recipientDid;

  /// The DIDComm plaintext message to send.
  final PlainTextMessage payload;

  /// The mediator's DID to route the message through. If not provided, the
  /// SDK's configured mediator DID is used.
  final String? mediatorDid;

  /// The control-plane notification type to include, if the recipient
  /// should be notified out-of-band about this message.
  final String? notifyChannelType;

  /// Whether the message is sent without being queued for later delivery.
  final bool ephemeral;

  /// How long, in seconds, the mediator should hold the message for pickup
  /// before it expires.
  final int? forwardExpiryInSeconds;
}
