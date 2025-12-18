import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import '../protocol/contact_card/contact_card.dart';

/// Converter extension for Control Plane ContactCard to Core ContactCard.
extension ContactCardConverterX on cp.ContactCard {
  ContactCard toCoreContactCard() {
    return ContactCard(did: did, type: type, contactInfo: contactInfo);
  }
}
