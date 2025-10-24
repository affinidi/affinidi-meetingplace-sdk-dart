import 'package:meeting_place_core/meeting_place_core.dart';

enum _VCardPaths {
  firstName(['n', 'given']),
  lastName(['n', 'surname']),
  email(['email', 'type', 'work']),
  mobile(['tel', 'type', 'cell']),
  profilePic(['photo']),
  meetingplaceIdentityCardColor(['x-meetingplace-identity-card-color']);

  const _VCardPaths(this.paths);
  final List<String> paths;
}

/// Extension on VCard to get and set common fields.
/// Fields include first name, last name, email, mobile number, profile picture,
/// and MeetingPlace identity card color.
extension VCardFieldsKeys on VCard {
  String _getVcardPathValue(
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

  void _setVcardPathValue(
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

  /// Gets or sets the first name in the VCard.
  String get firstName =>
      _getVcardPathValue(values, _VCardPaths.firstName.paths);
  set firstName(String value) =>
      _setVcardPathValue(values, _VCardPaths.firstName.paths, value);

  /// Gets or sets the last name in the VCard.
  String get lastName => _getVcardPathValue(values, _VCardPaths.lastName.paths);
  set lastName(String value) =>
      _setVcardPathValue(values, _VCardPaths.lastName.paths, value);

  /// Gets or sets the email in the VCard.
  String get email => _getVcardPathValue(values, _VCardPaths.email.paths);
  set email(String value) =>
      _setVcardPathValue(values, _VCardPaths.email.paths, value);

  /// Gets or sets the mobile number in the VCard.
  String get mobile => _getVcardPathValue(values, _VCardPaths.mobile.paths);
  set mobile(String value) =>
      _setVcardPathValue(values, _VCardPaths.mobile.paths, value);

  /// Gets or sets the profile picture in the VCard.
  String get profilePic => _getVcardPathValue(
        values,
        _VCardPaths.profilePic.paths,
        defaultValue: '',
      );
  set profilePic(String value) =>
      _setVcardPathValue(values, _VCardPaths.profilePic.paths, value);

  /// Gets or sets the MeetingPlace identity card color in the VCard.
  String get meetingplaceIdentityCardColor => _getVcardPathValue(
        values,
        _VCardPaths.meetingplaceIdentityCardColor.paths,
      );
  set meetingplaceIdentityCardColor(String value) => _setVcardPathValue(
        values,
        _VCardPaths.meetingplaceIdentityCardColor.paths,
        value,
      );
}
