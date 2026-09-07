/// The kind of connection offer to publish or accept.
enum SDKConnectionOfferType {
  /// A regular one-to-one connection invitation.
  invitation,

  /// An invitation to join a group.
  groupInvitation,

  /// An outreach invitation sent to an existing connection.
  outreachInvitation,
}
