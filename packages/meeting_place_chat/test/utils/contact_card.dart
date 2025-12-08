import 'package:meeting_place_core/meeting_place_core.dart';

ContactCard contactCardFromMap(Map<String, dynamic> card,
    {String did = 'did:test', String type = 'human'}) {
  return ContactCard(
    did: did,
    type: type,
    contactInfo: Map<String, dynamic>.from(card),
  );
}
