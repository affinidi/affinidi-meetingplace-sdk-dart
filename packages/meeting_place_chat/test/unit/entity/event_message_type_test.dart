import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('EventMessage serialization', () {
    test('fromJson accepts an unknown future type string without throwing', () {
      final json = _baseJson()..['eventType'] = 'videoCallStarted';
      final msg = EventMessage.fromJson(json);
      expect(msg.eventType.value, equals('videoCallStarted'));
    });

    test(
      'fromJson with a known type string equals the corresponding constant',
      () {
        final json = _baseJson()..['eventType'] = 'groupMemberJoinedGroup';
        final msg = EventMessage.fromJson(json);
        expect(msg.eventType, equals(EventMessageType.groupMemberJoinedGroup));
      },
    );

    test('fromJson defaults type to ChatItemType.eventMessage when absent', () {
      final json = _baseJson()..remove('type');
      final msg = EventMessage.fromJson(json);
      expect(msg.type, equals(ChatItemType.eventMessage));
    });

    test(
      'data map with nested structure round-trips through toJson/fromJson',
      () {
        final data = {
          'memberDid': 'did:example:bob',
          'meta': {'joinedAt': '2026-01-01'},
        };
        final msg = EventMessage.fromJson(
          _baseJson()
            ..['data'] = data
            ..['eventType'] = 'groupMemberJoinedGroup',
        );
        final restored = EventMessage.fromJson(msg.toJson());

        expect(restored.data['memberDid'], equals('did:example:bob'));
        expect(
          (restored.data['meta'] as Map)['joinedAt'],
          equals('2026-01-01'),
        );
      },
    );

    test('toJson omits null fields (includeIfNull: false)', () {
      final json = EventMessage.fromJson(_baseJson()).toJson();
      expect(json.values, everyElement(isNotNull));
    });
  });
}

Map<String, dynamic> _baseJson() => {
  'chatId': 'c1',
  'messageId': 'e1',
  'senderDid': 'did:example:alice',
  'isFromMe': false,
  'dateCreated': '2026-01-01T00:00:00.000Z',
  'status': 'received',
  'type': 'eventMessage',
  'eventType': 'groupDeleted',
  'data': <String, dynamic>{},
};
