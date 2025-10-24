import 'package:meeting_place_core/meeting_place_core.dart';

class VCardFixture {
  static final VCard alicePrimaryVCard = VCard(
    values: {
      'n': {'given': 'Alice'},
    },
  );

  static final VCard bobPrimaryVCard = VCard(
    values: {
      'n': {'given': 'Bob', 'surname': 'A.'},
    },
  );

  static final VCard charliePrimaryVCard = VCard(
    values: {
      'n': {'given': 'Charlie', 'surname': 'A.'},
    },
  );
}
