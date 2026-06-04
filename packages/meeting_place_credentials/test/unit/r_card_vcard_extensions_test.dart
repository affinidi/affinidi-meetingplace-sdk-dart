import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:test/test.dart';

void main() {
  group('RCardVCardExtension.toVCard', () {
    test('produces BEGIN:VCARD and END:VCARD markers', () {
      const subject = RCardSubject(firstName: 'Alice');
      final vCard = subject.toVCard();
      expect(vCard, contains('BEGIN:VCARD\r\n'));
      expect(vCard, contains('END:VCARD\r\n'));
    });

    test('includes VERSION:3.0', () {
      const subject = RCardSubject(firstName: 'Alice');
      expect(subject.toVCard(), contains('VERSION:3.0\r\n'));
    });

    test('N field has lastName;firstName format', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      expect(subject.toVCard(), contains('N:Smith;Alice;;;\r\n'));
    });

    test('FN field is "firstName lastName"', () {
      const subject = RCardSubject(firstName: 'Alice', lastName: 'Smith');
      expect(subject.toVCard(), contains('FN:Alice Smith\r\n'));
    });

    test('includes EMAIL field', () {
      const subject = RCardSubject(email: 'alice@example.com');
      expect(subject.toVCard(), contains('EMAIL:alice@example.com\r\n'));
    });

    test('includes TEL field with cell type', () {
      const subject = RCardSubject(phone: '+1234567890');
      expect(subject.toVCard(), contains('TEL;TYPE=cell:+1234567890\r\n'));
    });

    test('includes ORG field', () {
      const subject = RCardSubject(company: 'ACME');
      expect(subject.toVCard(), contains('ORG:ACME\r\n'));
    });

    test('includes TITLE field', () {
      const subject = RCardSubject(position: 'Engineer');
      expect(subject.toVCard(), contains('TITLE:Engineer\r\n'));
    });

    test('includes URL field for website', () {
      const subject = RCardSubject(website: 'https://example.com');
      expect(subject.toVCard(), contains('URL:https://example.com\r\n'));
    });

    test('includes URL field for social', () {
      const subject = RCardSubject(social: 'https://social.example.com/alice');
      expect(
        subject.toVCard(),
        contains('URL:https://social.example.com/alice\r\n'),
      );
    });

    test('includes NOTE field when notes param is provided', () {
      const subject = RCardSubject(firstName: 'Alice');
      expect(subject.toVCard(notes: 'Met at conference'), contains('NOTE:'));
    });

    test('omits optional fields when null or empty', () {
      const subject = RCardSubject(firstName: 'Alice');
      final vCard = subject.toVCard();
      expect(vCard, isNot(contains('EMAIL')));
      expect(vCard, isNot(contains('TEL')));
      expect(vCard, isNot(contains('ORG')));
    });

    test('omits N and FN when both firstName and lastName are null', () {
      const subject = RCardSubject(email: 'alice@example.com');
      final vCard = subject.toVCard();
      expect(vCard, isNot(contains('\nN:')));
      expect(vCard, isNot(contains('\nFN:')));
    });

    test('escapes semicolons in field values', () {
      const subject = RCardSubject(company: 'Doe; Sons');
      expect(subject.toVCard(), contains(r'ORG:Doe\; Sons'));
    });

    test('escapes commas in field values', () {
      const subject = RCardSubject(company: 'Foo, Bar');
      expect(subject.toVCard(), contains(r'ORG:Foo\, Bar'));
    });

    test('escapes backslashes in field values', () {
      const subject = RCardSubject(company: r'A\B');
      expect(subject.toVCard(), contains(r'ORG:A\\B'));
    });

    test('all lines end with CRLF', () {
      const subject = RCardSubject(
        firstName: 'Alice',
        lastName: 'Smith',
        email: 'alice@example.com',
      );
      final lines = subject.toVCard().split('\r\n');
      // Last element after final \r\n split will be empty string — that's fine.
      for (final line in lines.where((l) => l.isNotEmpty)) {
        expect(line, isNot(contains('\n')));
      }
    });
  });
}
