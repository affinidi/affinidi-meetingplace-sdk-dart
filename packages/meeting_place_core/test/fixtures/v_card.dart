import 'package:meeting_place_core/src/protocol/v_card/contact_card.dart';

class VCardFixture {
  static final ContactCard alicePrimaryVCard = ContactCard(
    values: {
      'n': {'given': 'Alice'},
    },
  );

  static final ContactCard bobPrimaryVCard = ContactCard(
    values: {
      'n': {'given': 'Bob', 'surname': 'A.'},
    },
  );

  static final ContactCard charliePrimaryVCard = ContactCard(
    values: {
      'n': {'given': 'Charlie', 'surname': 'A.'},
    },
  );
}
