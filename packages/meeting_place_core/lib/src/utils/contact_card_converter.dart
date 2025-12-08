import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import '../entity/contact_card.dart';

ContactCard toCoreContactCard(cp.ContactCard card,
    {required String did, required String type}) {
  return ContactCard(did: did, type: type, contactInfo: card.toJson()['contactInfo'] as Map<String, dynamic>);
}
