import '../contact_card.dart';
import 'contact_card_parser.dart';

class ContactCardDefaultParser implements ContactCardParser {
  @override
  String get schema => 'default';

  @override
  String getSenderInfo(ContactCard contactCard) => 'Anonymous';
}
