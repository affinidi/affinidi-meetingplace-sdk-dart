// ignore_for_file: constant_identifier_names
// TODO: change enum to comply with linting rules

enum DiscoveryNotificationType {
  ChannelActivity,
  InvitationAccept,
  InvitationGroupAccept,
  GroupMembershipFinalised,
  OfferFinalised,
  InvitationOutreach;

  static const Map<DiscoveryNotificationType, String> stringValues = {
    DiscoveryNotificationType.ChannelActivity: 'ChannelActivity',
    DiscoveryNotificationType.InvitationAccept: 'InvitationAccept',
    DiscoveryNotificationType.InvitationGroupAccept: 'InvitationGroupAccept',
    DiscoveryNotificationType.OfferFinalised: 'OfferFinalised',
    DiscoveryNotificationType.GroupMembershipFinalised:
        'GroupMembershipFinalised',
    DiscoveryNotificationType.InvitationOutreach: 'InvitationOutreach',
  };

  String get value => stringValues[this]!;
}
