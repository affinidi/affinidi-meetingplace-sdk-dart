import 'package:didcomm/didcomm.dart';

import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// A message that can be sent through [MeetingPlaceCoreSDK.sendMessage],
/// regardless of the underlying transport.
abstract class OutgoingMessage {
  const OutgoingMessage({required this.senderDid});

  /// DID of the sender. Used by CoreSDK to resolve a `DidManager` for the
  /// outgoing operation.
  final String senderDid;
}

/// Parameters required to dispatch a control-plane channel notification.
/// Either an individual peer or all members of a group are notified,
/// depending on the concrete subtype.
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
  });

  /// DID of the recipient whose `Channel.otherPartyNotificationToken` is
  /// used to address the notification.
  final String recipientDid;
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
