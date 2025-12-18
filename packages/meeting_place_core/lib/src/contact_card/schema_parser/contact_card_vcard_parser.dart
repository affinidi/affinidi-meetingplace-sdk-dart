import '../contact_card.dart';
import 'contact_card_parser.dart';

enum _ContactCardPaths {
  firstName(['n', 'given']);

  const _ContactCardPaths(this.paths);
  final List<String> paths;
}

class ContactCardVcardParser implements ContactCardParser {
  @override
  String get schema => 'https://affinidi.com/schemas/1.0/vcard.json';

  @override
  String getSenderInfo(ContactCard contactCard) {
    return _getContactCardPathValue(
        contactCard.contactInfo, _ContactCardPaths.firstName.paths);
  }

  String _getContactCardPathValue(
    Map<dynamic, dynamic> values,
    List<String> pathKeys, {
    String defaultValue = '',
  }) {
    if (pathKeys.isEmpty) return defaultValue;

    var parentElement = values;
    for (final pathKey in pathKeys) {
      final elementAtPath = parentElement[pathKey];
      if (elementAtPath == null) {
        return defaultValue;
      }

      if ((pathKey == pathKeys.last) && elementAtPath is String) {
        return elementAtPath;
      }

      if (elementAtPath is Map<dynamic, dynamic>) {
        parentElement = elementAtPath;
      }
    }

    return defaultValue;
  }
}
