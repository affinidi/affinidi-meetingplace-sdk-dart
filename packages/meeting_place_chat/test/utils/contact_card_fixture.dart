import 'package:meeting_place_core/meeting_place_core.dart';

class ContactCardFixture {
  static final Map<String, dynamic> alicePrimaryCardInfo = {
    'n': {'given': 'Alice'},
  };

  static final Map<String, dynamic> bobPrimaryCardInfo = {
    'n': {'given': 'Bob', 'surname': 'A.'},
  };

  static final Map<String, dynamic> charliePrimaryCardInfo = {
    'n': {'given': 'Charlie', 'surname': 'A.'},
  };

  static ContactCard getContactCardFixture({
    String? did,
    Map<String, dynamic>? contactInfo,
  }) {
    return ContactCard(
      did: did ?? 'did:test:default',
      type: 'human',
      schema: 'https://affinidi.com/schemas/v1/sample-contact-card',
      contactInfo: contactInfo ??
          {
            'n': {'given': 'Default'}
          },
    );
  }
}
