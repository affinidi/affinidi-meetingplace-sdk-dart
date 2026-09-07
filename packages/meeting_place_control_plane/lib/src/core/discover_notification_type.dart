enum DiscoveryNotificationType {
  channelActivity,
  invitationAccept,
  invitationGroupAccept,
  groupMembershipFinalised,
  offerFinalised,
  invitationOutreach;

  static const Map<DiscoveryNotificationType, String> stringValues = {
    DiscoveryNotificationType.channelActivity: 'ChannelActivity',
    DiscoveryNotificationType.invitationAccept: 'InvitationAccept',
    DiscoveryNotificationType.invitationGroupAccept: 'InvitationGroupAccept',
    DiscoveryNotificationType.offerFinalised: 'OfferFinalised',
    DiscoveryNotificationType.groupMembershipFinalised:
        'GroupMembershipFinalised',
    DiscoveryNotificationType.invitationOutreach: 'InvitationOutreach',
  };

  String get value => stringValues[this]!;
}
