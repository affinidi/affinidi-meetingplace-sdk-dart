import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:meeting_place_relationship/src/rcard/model/j_card.dart';
import 'package:meeting_place_relationship/src/rcard/model/r_card_credential_subject.dart';
import 'package:test/test.dart';

void main() {
  group('RCardCredentialSubject.fromJson — flat-field format', () {
    test('throws FormatException — flat-field format is not supported', () {
      expect(
        () => RCardCredentialSubject.fromJson({
          'id': 'did:key:z1',
          'firstName': 'Alice',
          'lastName': 'Smith',
        }),
        throwsA(isA<FormatException>()),
      );
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
