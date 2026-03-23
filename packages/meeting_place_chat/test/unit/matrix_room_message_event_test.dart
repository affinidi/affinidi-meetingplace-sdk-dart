import 'dart:convert';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/src/utils/matrix_room_message_event.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
  group('MatrixRoomMessageEvent', () {
    test('parses audio attachments and mentions from Matrix content', () {
      final event = MatrixRoomMessageEvent.fromParts(
        eventId: r'$event:example.com',
        senderId: '@bob:example.com',
        type: 'm.room.message',
        originServerTs: DateTime.utc(2026, 3, 23),
        content: {
          'body': 'voice note',
          'msgtype': matrix.MessageTypes.Audio,
          'url': 'mxc://example.com/audio123',
          'info': {'mimetype': 'audio/ogg', 'duration': 1200},
          'm.mentions': {
            'user_ids': ['@alice:example.com'],
          },
        },
      );

      expect(event.isRoomMessage, isTrue);
      expect(event.mentionsUser('@alice:example.com'), isTrue);
      expect(event.body, 'voice note');
      expect(event.mentionedUserIds, ['@alice:example.com']);

      final attachment = event.attachment;
      expect(attachment, isNotNull);
      expect(attachment!.uri, 'mxc://example.com/audio123');
      expect(attachment.filename, 'voice note');
      expect(attachment.mediaType, 'audio/ogg');
      expect(attachment.format, AttachmentFormat.matrixAudio.value);

      final metadata =
          jsonDecode(attachment.metadataJson) as Map<String, dynamic>;
      expect(metadata['msgtype'], matrix.MessageTypes.Audio);
      expect(metadata['duration'], 1200);
    });

    test('ignores unsupported message types for attachments', () {
      final event = MatrixRoomMessageEvent.fromParts(
        eventId: r'$event:example.com',
        senderId: '@bob:example.com',
        type: 'm.room.message',
        originServerTs: DateTime.utc(2026, 3, 23),
        content: {
          'body': 'plain text',
          'msgtype': matrix.MessageTypes.Text,
          'url': 'mxc://example.com/text123',
        },
      );

      expect(event.attachment, isNull);
    });
  });
}
