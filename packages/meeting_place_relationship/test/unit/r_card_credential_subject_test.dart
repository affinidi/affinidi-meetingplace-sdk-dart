import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('RCardCredentialSubject.fromJson — flat-field format', () {
    test('parses all fields from a flat map', () {
      final subject = RCardCredentialSubject.fromJson({
        'id': 'did:key:z1',
        'firstName': 'Alice',
        'lastName': 'Smith',
        'email': 'alice@example.com',
        'phone': '+1234567890',
        'profilePic': 'https://pic.example.com/alice.jpg',
        'address': '123 Main St',
      });

      expect(subject.id, 'did:key:z1');
      expect(subject.name, 'Alice Smith');
      expect(subject.email, 'alice@example.com');
      expect(subject.phone, '+1234567890');
      expect(subject.profilePic, 'https://pic.example.com/alice.jpg');
      expect(subject.address, '123 Main St');
    });

    test('derives name from firstName and lastName', () {
      final subject = RCardCredentialSubject.fromJson({
        'id': 'did:key:z1',
        'firstName': 'Alice',
        'lastName': 'Smith',
      });
      expect(subject.name, 'Alice Smith');
    });

    test('falls back to name field when no firstName/lastName', () {
      final subject = RCardCredentialSubject.fromJson({
        'id': 'did:key:z1',
        'name': 'Alice Smith',
      });
      expect(subject.name, 'Alice Smith');
    });

    test('trims whitespace from string fields', () {
      final subject = RCardCredentialSubject.fromJson({
        'id': '  did:key:z1  ',
        'firstName': '  Alice  ',
        'lastName': '  Smith  ',
        'email': '  alice@example.com  ',
      });
      expect(subject.id, 'did:key:z1');
      expect(subject.name, 'Alice Smith');
      expect(subject.email, 'alice@example.com');
    });

    test('captures unknown keys as additionalFields', () {
      final subject = RCardCredentialSubject.fromJson({
        'id': 'did:key:z1',
        'firstName': 'Alice',
        'customField': 'custom value',
      });
      expect(subject.additionalFields, {'customField': 'custom value'});
    });

    test('additionalFields is null when no unknown keys present', () {
      final subject = RCardCredentialSubject.fromJson({
        'id': 'did:key:z1',
        'firstName': 'Alice',
      });
      expect(subject.additionalFields, isNull);
    });

    test('handles missing optional fields gracefully', () {
      final subject = RCardCredentialSubject.fromJson({'id': 'did:key:z1'});
      expect(subject.name, isNull);
      expect(subject.email, isNull);
      expect(subject.phone, isNull);
    });
  });

  group('RCardCredentialSubject.fromJson — jCard format', () {
    test('parses from a jCard-encoded card field', () {
      final jCard = JCard.encode(
        const RCardSubject(
          firstName: 'Bob',
          lastName: 'Jones',
          email: 'bob@example.com',
          phone: '+9876543210',
        ),
      );
      final subject = RCardCredentialSubject.fromJson({
        'id': 'did:key:z2',
        'card': jCard,
      });

      expect(subject.id, 'did:key:z2');
      expect(subject.name, 'Bob Jones');
      expect(subject.email, 'bob@example.com');
      expect(subject.phone, '+9876543210');
    });

    test('throws FormatException when card field is not a valid jCard', () {
      expect(
        () => RCardCredentialSubject.fromJson({
          'id': 'did:key:z2',
          'card': 'not a jCard',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RCardCredentialSubject.toJson', () {
    test('round-trips through toJson', () {
      const original = RCardCredentialSubject(
        id: 'did:key:z1',
        name: 'Alice Smith',
        email: 'alice@example.com',
        phone: '+1234567890',
        profilePic: 'https://pic.example.com',
        address: '123 Main St',
      );
      final json = original.toJson();
      expect(json['id'], original.id);
      expect(json['name'], original.name);
      expect(json['email'], original.email);
      expect(json['phone'], original.phone);
      expect(json['profilePic'], original.profilePic);
      expect(json['address'], original.address);
    });

    test('omits null fields from toJson output', () {
      const subject = RCardCredentialSubject(id: 'did:key:z1');
      final json = subject.toJson();
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('email'), isFalse);
    });

    test('spreads additionalFields into toJson output', () {
      const subject = RCardCredentialSubject(
        id: 'did:key:z1',
        additionalFields: {'custom': 'value'},
      );
      expect(subject.toJson()['custom'], 'value');
    });
  });
}
