import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import '../entity/contact_card.dart';

/// Converter extension for Control Plane ContactCard to Core ContactCard.
extension ContactCardConverterX on cp.ContactCard {
  ContactCard toCoreContactCard({required String did, required String type}) {
    return ContactCard(
      did: did,
      type: type,
      contactInfo: toJson()['contactInfo'] as Map<String, dynamic>,
    );
  }
}
