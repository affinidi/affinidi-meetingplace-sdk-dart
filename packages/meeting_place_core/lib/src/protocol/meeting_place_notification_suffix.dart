enum MeetingPlaceNotificationTypeSuffix {
  invitationAccept('/mpx-discovery/invitation-accept'),
  invitationGroupAccept('/mpx-discovery/invitation-accept-group'),
  invitationOutreach('/mpx-discovery/invitation-outreach'),
  offerFinalised('/mpx-discovery/offer-finalised'),
  channelActivity('/mpx-discovery/channel-activity'),
  groupMembershipFinalised('/mpx-discovery/group-membership-finalised');

  const MeetingPlaceNotificationTypeSuffix(this.value);

  final String value;
}
