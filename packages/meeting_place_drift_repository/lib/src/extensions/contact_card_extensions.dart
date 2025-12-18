import 'package:meeting_place_core/meeting_place_core.dart';

enum _ContactCardPaths {
  firstName([
    'n',
    'given',
  ]),
  lastName([
    'n',
    'surname',
  ]),
  email([
    'email',
    'type',
    'work',
  ]),
  mobile([
    'tel',
    'type',
    'cell',
  ]),
  profilePic([
    'photo',
  ]),
  meetingplaceIdentityCardColor([
    'x-meetingplace-identity-card-color',
  ]);

  const _ContactCardPaths(this.paths);
  final List<String> paths;
}

extension ContactCardFieldsKeys on ContactCard {
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

  void _setContactCardPathValue(
    Map<dynamic, dynamic> values,
    List<String> pathKeys,
    String value,
  ) {
    if (pathKeys.isEmpty) return;

    var parentElement = values;
    for (final pathKey in pathKeys) {
      if (pathKey == pathKeys.last) continue;

      final elementAtPath = parentElement[pathKey];
      if (elementAtPath == null) {
        var newNode = <dynamic, dynamic>{};
        parentElement[pathKey] = newNode;
        parentElement = newNode;
      } else if (elementAtPath is Map<dynamic, dynamic>) {
        parentElement = elementAtPath;
      }
    }

    parentElement[pathKeys.last] = value;
  }

  String get firstName =>
      _getContactCardPathValue(contactInfo, _ContactCardPaths.firstName.paths);
  set firstName(String value) => _setContactCardPathValue(
        contactInfo,
        _ContactCardPaths.firstName.paths,
        value,
      );

  String get lastName =>
      _getContactCardPathValue(contactInfo, _ContactCardPaths.lastName.paths);
  set lastName(String value) => _setContactCardPathValue(
        contactInfo,
        _ContactCardPaths.lastName.paths,
        value,
      );

  String get email =>
      _getContactCardPathValue(contactInfo, _ContactCardPaths.email.paths);
  set email(String value) => _setContactCardPathValue(
        contactInfo,
        _ContactCardPaths.email.paths,
        value,
      );

  String get mobile =>
      _getContactCardPathValue(contactInfo, _ContactCardPaths.mobile.paths);
  set mobile(String value) => _setContactCardPathValue(
        contactInfo,
        _ContactCardPaths.mobile.paths,
        value,
      );

  String get profilePic => _getContactCardPathValue(
        contactInfo,
        _ContactCardPaths.profilePic.paths,
        defaultValue: '',
      );
  set profilePic(String value) => _setContactCardPathValue(
        contactInfo,
        _ContactCardPaths.profilePic.paths,
        value,
      );

  String get meetingplaceIdentityCardColor => _getContactCardPathValue(
        contactInfo,
        _ContactCardPaths.meetingplaceIdentityCardColor.paths,
      );
  set meetingplaceIdentityCardColor(String value) => _setContactCardPathValue(
        contactInfo,
        _ContactCardPaths.meetingplaceIdentityCardColor.paths,
        value,
      );
}
