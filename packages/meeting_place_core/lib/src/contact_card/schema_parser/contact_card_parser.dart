import '../contact_card.dart';

abstract interface class ContactCardParser {
  String get schema;
  String getSenderInfo(ContactCard contactCard);
}
