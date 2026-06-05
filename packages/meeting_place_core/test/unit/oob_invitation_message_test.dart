import 'package:meeting_place_core/src/protocol/message/oob_invitation_message/oob_invitation_message.dart';
import 'package:test/test.dart';

void main() {
  group('OobInvitationMessage.fromBase64 security tests', () {
    test('should throw FormatException for JSON number (int cast failure)', () {
      // Payload "MA" decodes to JSON: 0
      const payload = 'MA';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });

    test('should throw FormatException for JSON string (String cast failure)', () {
      // Payload "IjEi" decodes to JSON: "1"
      const payload = 'IjEi';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });

    test('should throw FormatException for JSON null (Null cast failure)', () {
      // Payload "bnVsbA" decodes to JSON: null
      const payload = 'bnVsbA';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });

    test('should throw FormatException for JSON array (List cast failure)', () {
      // Payload "WzAsIiIse31d" decodes to JSON: [0,"",{}]
      const payload = 'WzAsIiIse31d';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });

    test('should throw FormatException for missing required field "id"', () {
      // Payload "eyJmcm9tIjoieCJ9" decodes to JSON: {"from":"x"}
      const payload = 'eyJmcm9tIjoieCJ9';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });

    test('should throw FormatException for missing required field "body"', () {
      // Payload "eyJpZCI6ImEiLCJmcm9tIjoiYiJ9" decodes to JSON: {"id":"a","from":"b"}
      const payload = 'eyJpZCI6ImEiLCJmcm9tIjoiYiJ9';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });

    test('should throw FormatException for wrong field type (int instead of String)', () {
      // Payload "eyJpZCI6MSwiZnJvbSI6ImEiLCJib2R5Ijp7fX0" decodes to JSON: {"id":1,"from":"a","body":{}}
      const payload = 'eyJpZCI6MSwiZnJvbSI6ImEiLCJib2R5Ijp7fX0';
      expect(
        () => OobInvitationMessage.fromBase64(payload),
        throwsFormatException,
      );
    });
  });

  group('OobInvitationMessage.fromJson security tests', () {
    test('should throw FormatException for null id field', () {
      final json = {
        'id': null,
        'from': 'did:test:alice',
        'body': {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
      };
      expect(
        () => OobInvitationMessage.fromJson(json),
        throwsFormatException,
      );
    });

    test('should throw FormatException for int id field', () {
      final json = {
        'id': 123,
        'from': 'did:test:alice',
        'body': {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
      };
      expect(
        () => OobInvitationMessage.fromJson(json),
        throwsFormatException,
      );
    });

    test('should throw FormatException for null from field', () {
      final json = {
        'id': 'test-id',
        'from': null,
        'body': {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
      };
      expect(
        () => OobInvitationMessage.fromJson(json),
        throwsFormatException,
      );
    });

    test('should throw FormatException for null body field', () {
      final json = {
        'id': 'test-id',
        'from': 'did:test:alice',
        'body': null,
      };
      expect(
        () => OobInvitationMessage.fromJson(json),
        throwsFormatException,
      );
    });

    test('should throw FormatException for array body field', () {
      final json = {
        'id': 'test-id',
        'from': 'did:test:alice',
        'body': ['not', 'a', 'map'],
      };
      expect(
        () => OobInvitationMessage.fromJson(json),
        throwsFormatException,
      );
    });

    test('should throw FormatException for string created_time field', () {
      final json = {
        'id': 'test-id',
        'from': 'did:test:alice',
        'body': {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
        'created_time': 'not-an-int',
      };
      expect(
        () => OobInvitationMessage.fromJson(json),
        throwsFormatException,
      );
    });
  });

  group('OobInvitationMessage happy path', () {
    test('should successfully parse valid OOB invitation', () {
      final json = {
        'id': 'test-id-123',
        'from': 'did:test:alice',
        'body': {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
      };

      final message = OobInvitationMessage.fromJson(json);

      expect(message.id, 'test-id-123');
      expect(message.from, 'did:test:alice');
      expect(message.body.goalCode, 'connect');
      expect(message.body.goal, 'Start relationship');
      expect(message.body.accept, ['didcomm/v2']);
    });

    test('should successfully parse valid OOB invitation with created_time', () {
      final json = {
        'id': 'test-id-123',
        'from': 'did:test:alice',
        'body': {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
        'created_time': 1609459200, // 2021-01-01 00:00:00 UTC in seconds
      };

      final message = OobInvitationMessage.fromJson(json);

      expect(message.id, 'test-id-123');
      expect(message.from, 'did:test:alice');
      expect(message.createdTime, DateTime.utc(2021, 1, 1));
    });
  });
}
