import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ConciergeMessage serialization', () {
    test('fromJson accepts an unknown future type string without throwing', () {
      final json = _baseJson()..['conciergeType'] = 'someNewTypeFromServer';
      final msg = ConciergeMessage.fromJson(json);
      expect(msg.conciergeType.value, equals('someNewTypeFromServer'));
    });

    test(
      'fromJson with a known type string equals the corresponding constant',
      () {
        final json = _baseJson()..['conciergeType'] = 'permissionToJoinGroup';
        final msg = ConciergeMessage.fromJson(json);
        expect(
          msg.conciergeType,
          equals(ConciergeMessageType.permissionToJoinGroup),
        );
      },
    );

    test(
      'fromJson defaults type to ChatItemType.conciergeMessage when absent',
      () {
        final json = _baseJson()..remove('type');
        final msg = ConciergeMessage.fromJson(json);
        expect(msg.type, equals(ChatItemType.conciergeMessage));
      },
    );

    test(
      'data map with nested structure round-trips through toJson/fromJson',
      () {
        final data = {
          'groupId': 'g-42',
          'meta': {'requestedAt': '2026-01-01'},
        };
        final msg = ConciergeMessage.fromJson(
          _baseJson()
            ..['data'] = data
            ..['conciergeType'] = 'permissionToJoinGroup',
        );
        final restored = ConciergeMessage.fromJson(msg.toJson());

        expect(restored.data['groupId'], equals('g-42'));
        expect(
          (restored.data['meta'] as Map)['requestedAt'],
          equals('2026-01-01'),
        );
      },
    );

    test('toJson omits null fields (includeIfNull: false)', () {
      final json = ConciergeMessage.fromJson(_baseJson()).toJson();
      expect(json.values, everyElement(isNotNull));
    });
  });
}

Map<String, dynamic> _baseJson() => {
  'chatId': 'c1',
  'messageId': 'm1',
  'senderDid': 'did:example:alice',
  'isFromMe': false,
  'dateCreated': '2026-01-01T00:00:00.000Z',
  'status': 'userInput',
  'type': 'conciergeMessage',
  'conciergeType': 'permissionToUpdateProfile',
  'data': <String, dynamic>{},
};
