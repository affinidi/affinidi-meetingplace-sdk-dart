enum MeetingPlaceNotificationTypeSuffix {
  invitationAccept('/mpx/control-plane/invitation-accept'),
  invitationGroupAccept('/mpx/control-plane/invitation-accept-group'),
  invitationOutreach('/mpx/control-plane/invitation-outreach'),
  offerFinalised('/mpx/control-plane/offer-finalised'),
  channelActivity('/mpx/control-plane/channel-activity'),
  groupMembershipFinalised('/mpx/control-plane/group-membership-finalised');

  const MeetingPlaceNotificationTypeSuffix(this.value);

  final String value;
}
