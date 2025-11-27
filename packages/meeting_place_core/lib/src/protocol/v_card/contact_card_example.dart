import '../../../meeting_place_core.dart';

class ContactCardExample extends ContactCard {
  ContactCardExample(
      {required super.did, required super.contactType, required super.info});

  @override
  String get displayName => info['name'] as String? ?? 'No Name';
}
