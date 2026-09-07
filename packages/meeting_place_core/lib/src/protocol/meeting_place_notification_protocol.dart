/// The DIDComm protocols used to notify a party's other devices or
/// mediators about Meeting Place activity.
enum MeetingPlaceNotificationProtocol {
  /// Notifies of activity on a channel.
  channelActivity(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/channel-activity',
  ),

  /// Notifies that a connection request was approved.
  connectionRequestApproval(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-connection-request-approval',
  ),

  /// Notifies that an invitation was accepted.
  invitationAcceptance(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-invitation-acceptance',
  ),

  /// Notifies that a group invitation was accepted.
  invitationAcceptanceGroup(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-invitation-acceptance-group',
  ),

  /// Notifies that a group membership was finalised.
  groupMembershipFinalised(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/group-membership-finalised',
  ),

  /// Notifies that an outreach invitation was sent.
  outreachInvitation(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-outreach-invitation',
  );

  const MeetingPlaceNotificationProtocol(this.value);

  /// The DIDComm protocol URI identifying this notification protocol.
  final String value;
}
