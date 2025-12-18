import 'package:meeting_place_core/meeting_place_core.dart';

class ContactCardFixture {
  static ContactCard getContactCardFixture({
    String? did,
    Map<String, dynamic>? contactInfo,
  }) => ContactCard(
    did: did ?? 'did:test:contact-card',
    type: 'individual',
    contactInfo: contactInfo ?? {'fullName': 'Test User'},
  );
}
