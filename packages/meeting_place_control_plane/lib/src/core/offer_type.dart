/// The kind of connection offer published on the control plane.
enum OfferType {
  /// A 1:1 invitation offer.
  invitation('invitation'),

  /// A group invitation offer.
  groupInvitation('groupInvitation'),

  /// An outreach invitation offer, such as a broadcast or service
  /// invitation.
  outreachInvitation('outreachInvitation');

  const OfferType(this.value);

  /// The wire string representation of this offer type.
  final String value;

  /// Maps the `contactAttributes` integer code used by the control plane
  /// API to the corresponding [OfferType].
  ///
  /// Throws [UnimplementedError] if [value] is not a known contact
  /// attribute code.
  static OfferType fromContactAttributes(int value) {
    switch (value) {
      case 1:
        return invitation;
      case 2:
        return outreachInvitation;
      case 64:
        return groupInvitation;
      default:
        throw UnimplementedError();
    }
  }
}
