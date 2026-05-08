import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('JCard.encode', () {
    test('always emits version as first property', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      final jCard = JCard.encode(subject);
      final props = (jCard[1] as List).cast<List>();
      expect(props.first[0], 'version');
      expect(props.first[3], '4.0');
    });

    test('emits fn and n for a subject with first and last name', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      final jCard = JCard.encode(subject);
      final props = (jCard[1] as List).cast<List>();
      final propNames = props.map((p) => p[0]).toList();
      expect(propNames, containsAll(['fn', 'n']));
    });

    test('n structured value has family name at index 0 and given at 1', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      final jCard = JCard.encode(subject);
      final props = (jCard[1] as List).cast<List>();
      final n = props.firstWhere((p) => p[0] == 'n');
      final structured = n[3] as List;
      expect(structured[0], 'Smith');
      expect(structured[1], 'Alice');
    });

    test('fn value is "given family"', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      final jCard = JCard.encode(subject);
      final props = (jCard[1] as List).cast<List>();
      final fn = props.firstWhere((p) => p[0] == 'fn');
      expect(fn[3], 'Alice Smith');
    });

    test('uses RFC 6350 property names for all contact fields', () {
      const subject = RCardSubject(
        firstName: 'Alice',
        lastName: 'Smith',
        email: 'alice@example.com',
        phone: '+1234567890',
        profilePic: 'https://pic.example.com/alice.jpg',
        company: 'ACME',
        position: 'Engineer',
        website: 'https://example.com',
        social: 'https://social.example.com/alice',
      );
      final jCard = JCard.encode(subject);
      final props = (jCard[1] as List).cast<List>();
      final propNames = props.map((p) => p[0]).toSet();
      expect(
        propNames,
        containsAll([
          'version',
          'fn',
          'n',
          'email',
          'tel',
          'photo',
          'org',
          'title',
          'url',
          'x-socialprofile',
        ]),
      );
    });

    test('omits optional fields when null or empty', () {
      const subject = RCardSubject(firstName: 'Bob');
      final jCard = JCard.encode(subject);
      final props = (jCard[1] as List).cast<List>();
      final propNames = props.map((p) => p[0]).toList();
      expect(propNames, isNot(contains('email')));
      expect(propNames, isNot(contains('tel')));
    });

    test('outer structure is ["vcard", [...]]', () {
      const subject = RCardSubject(firstName: 'Bob');
      final jCard = JCard.encode(subject);
      expect(jCard[0], 'vcard');
      expect(jCard[1], isA<List>());
    });
  });

  group('JCard.decode', () {
    test('returns null for non-list input', () {
      expect(JCard.decode('not a list', null), isNull);
    });

    test('returns null when first element is not "vcard"', () {
      expect(JCard.decode(['vcal', <Object>[]], null), isNull);
    });

    test('returns null for a list shorter than 2 elements', () {
      expect(JCard.decode(['vcard'], null), isNull);
    });

    test('returns null when props element is not a List', () {
      expect(JCard.decode(['vcard', 'bad'], null), isNull);
    });

    test('round-trips an encoded subject back to the same values', () {
      const original = RCardSubject(
        id: 'did:key:z1',
        firstName: 'Alice',
        lastName: 'Smith',
        email: 'alice@example.com',
        phone: '+1234567890',
        profilePic: 'https://pic.example.com/alice.jpg',
        company: 'ACME',
        position: 'Engineer',
        website: 'https://example.com',
        social: 'https://social.example.com/alice',
      );
      final encoded = JCard.encode(original);
      final decoded = JCard.decode(encoded, original.id);
      expect(decoded, isNotNull);
      expect(decoded!['id'], original.id);
      expect(decoded['firstName'], original.firstName);
      expect(decoded['lastName'], original.lastName);
      expect(decoded['email'], original.email);
      expect(decoded['phone'], original.phone);
      expect(decoded['profilePic'], original.profilePic);
      expect(decoded['company'], original.company);
      expect(decoded['position'], original.position);
      expect(decoded['website'], original.website);
      expect(decoded['social'], original.social);
    });

    test('sets id from the provided argument', () {
      final encoded = JCard.encode(const RCardSubject(firstName: 'Carol'));
      final decoded = JCard.decode(encoded, 'did:key:z2');
      expect(decoded!['id'], 'did:key:z2');
    });

    test(
      'passes through unknown legacy camelCase keys for backward compat',
      () {
        final legacyCard = [
          'vcard',
          [
            ['version', const <String, dynamic>{}, 'text', '4.0'],
            ['profilePic', const <String, dynamic>{}, 'text', 'https://pic.io'],
          ],
        ];
        final decoded = JCard.decode(legacyCard, null);
        expect(decoded!['profilePic'], 'https://pic.io');
      },
    );

    test('ignores version and fn properties', () {
      final encoded = JCard.encode(
        const RCardSubject(firstName: 'Dave', lastName: 'Jones'),
      );
      final decoded = JCard.decode(encoded, null)!;
      expect(decoded.containsKey('version'), isFalse);
      expect(decoded.containsKey('fn'), isFalse);
    });
  });
}
