// ignore_for_file: constant_identifier_names
// TODO: change enum to comply with linting rules

enum ControlPlaneEventType {
  Unknown,
  InvitationAccept,
  InvitationGroupAccept,
  OfferFinalised,
  GroupMembershipFinalised,
  ChannelActivity,
  InvitationOutreach,
}

enum DiscoveryEventStatus { Unknown, New, Deleted, Processed }
