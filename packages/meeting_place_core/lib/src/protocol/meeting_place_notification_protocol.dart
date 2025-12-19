enum MeetingPlaceNotificationProtocol {
  channelActivity(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/channel-activity',
  ),

  connectionRequestApproval(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-connection-request-approval',
  ),

  invitationAcceptance(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-invitation-acceptance',
  ),

  invitationAcceptanceGroup(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-invitation-acceptance-group',
  ),

  groupMembershipFinalised(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/group-membership-finalised',
  ),

  outreachInvitation(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/notification-outreach-invitation',
  );

  const MeetingPlaceNotificationProtocol(this.value);

  final String value;
}
