import '../contact_card.dart';
import '../schema_parser/contact_card_default_parser.dart';
import '../schema_parser/contact_card_parser.dart';

class ContactCardSchemaRegistry {
  static final _schemas = <String, ContactCardParser>{};

  static void registerParsers(
    List<ContactCardParser> contactCardParsers,
  ) {
    for (final parser in contactCardParsers) {
      _schemas[parser.schema] = parser;
    }
  }

  static String getSenderInfo(ContactCard contactCard) {
    final schemaParser = _getSchemaParser(contactCard.schema);
    if (schemaParser != null) {
      return schemaParser.getSenderInfo(contactCard);
    }

    return ContactCardDefaultParser().getSenderInfo(contactCard);
  }

  static ContactCardParser? _getSchemaParser(String schema) {
    return _schemas[schema];
  }
}
