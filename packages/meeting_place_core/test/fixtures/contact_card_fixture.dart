import 'package:meeting_place_core/meeting_place_core.dart';

class ContactCardFixture {
  static ContactCard getContactCardFixture({
    String? did,
    Map<String, dynamic>? contactInfo,
  }) =>
      ContactCard(
        did: did ?? 'did:test:contact-card',
        type: 'individual',
        schema: 'https://affinidi.com/schemas/v1/sample-contact-card',
        contactInfo: contactInfo ?? {'fullName': 'Test User'},
      );
}
