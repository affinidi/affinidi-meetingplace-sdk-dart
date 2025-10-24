enum OfferType {
  invitation('invitation'),
  groupInvitation('groupInvitation'),
  outreachInvitation('outreachInvitation');

  const OfferType(this.value);
  final String value;

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
