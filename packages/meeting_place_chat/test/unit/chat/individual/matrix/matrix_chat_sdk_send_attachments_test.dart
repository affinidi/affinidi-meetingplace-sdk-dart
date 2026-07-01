import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/matrix_media_attachment.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/chat_typing_notification.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../_helpers/mocks.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

IndividualMatrixChatSDK _buildSdk({
  required MockCoreSDK core,
  required _MockChatRepository repo,
}) => IndividualMatrixChatSDK(
  coreSDK: core,
  did: _aliceDid,
  otherPartyDid: _bobDid,
  mediatorDid: _mediatorDid,
  chatRepository: repo,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

Channel _fakeChannel() => Channel(
  offerLink: 'https://example.com/offer',
  publishOfferDid: _aliceDid,
  mediatorDid: _mediatorDid,
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(did: _aliceDid, type: 'individual', contactInfo: {}),
  type: ChannelType.individual,
  isConnectionInitiator: true,
  otherPartyPermanentChannelDid: _bobDid,
);

void main() {
  late MockCoreSDK core;
  late _MockChatRepository repo;
  late IndividualMatrixChatSDK sdk;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      Message(
        chatId: '',
        messageId: '',
        senderDid: '',
        value: '',
        isFromMe: false,
        dateCreated: DateTime.utc(2026),
        status: ChatItemStatus.received,
      ),
    );
    registerFallbackValue(ChatTypingNotification(senderDid: '', active: false));
    registerFallbackValue(_fakeChannel());
    registerFallbackValue(const MatrixEventMediaReference('fallback'));
    registerFallbackValue(
      const IndividualChannelNotification(
        recipientDid: 'did:test:fb',
        type: 'chat-activity',
      ),
    );
  });

  setUp(() {
    core = MockCoreSDK();
    repo = _MockChatRepository();
    sdk = _buildSdk(core: core, repo: repo);

    final store = <String, ChatItem>{};

    when(
      () => core.getChannelByOtherPartyPermanentDid(any()),
    ).thenAnswer((_) async => _fakeChannel());

    when(() => core.updateChannel(any())).thenAnswer((_) async {});

    when(() => core.sendMessage(any())).thenAnswer((_) async => '\$event-id');

    when(() => repo.createMessage(any())).thenAnswer((inv) async {
      final item = inv.positionalArguments.first as ChatItem;
      store[item.messageId] = item;
      return item;
    });

    when(
      () => repo.getMessage(
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((inv) async {
      final messageId = inv.namedArguments[#messageId] as String;
      return store[messageId];
    });

    when(() => repo.updateMesssage(any())).thenAnswer((inv) async {
      final item = inv.positionalArguments.first as ChatItem;
      store[item.messageId] = item;
      return item;
    });
  });

  group('MatrixChatSDK.sendTextMessage multi-attachment', () {
    test('two attachments produce two sendMediaMessage calls', () async {
      var sendMediaCount = 0;
      when(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
          extraContent: any(named: 'extraContent'),
          notification: any(named: 'notification'),
        ),
      ).thenAnswer((_) async {
        sendMediaCount++;
        return '\$event-$sendMediaCount';
      });

      final attachments = [
        ChatAttachment(
          id: 'attachment-1',
          filename: 'a.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
          id: 'attachment-2',
          filename: 'b.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
      ];

      await sdk.sendTextMessage('Hello', attachments: attachments);

      verify(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
          extraContent: any(named: 'extraContent'),
          notification: any(named: 'notification'),
        ),
      ).called(2);

      // One logical Message is persisted (queued), then updated to sent.
      verify(() => repo.createMessage(any())).called(1);
      verify(() => repo.updateMesssage(any())).called(1);
    });

    test('caption is only passed on the first sendMediaMessage', () async {
      final captions = <String?>[];
      when(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
          extraContent: any(named: 'extraContent'),
          notification: any(named: 'notification'),
        ),
      ).thenAnswer((inv) async {
        captions.add(inv.namedArguments[#caption] as String?);
        return '\$event-${captions.length}';
      });

      final attachments = [
        ChatAttachment(
          id: 'attachment-1',
          filename: 'a.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
          id: 'attachment-2',
          filename: 'b.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
      ];

      await sdk.sendTextMessage('My caption', attachments: attachments);

      expect(captions, hasLength(2));
      expect(captions[0], 'My caption');
      expect(captions[1], isNull);
    });

    test(
      'same correlation id is sent for every attachment in the call',
      () async {
        final correlationIds = <String?>[];
        final attachmentIds = <String?>[];
        when(
          () => core.sendMediaMessage(
            any(),
            any(),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
            caption: any(named: 'caption'),
            extraContent: any(named: 'extraContent'),
            notification: any(named: 'notification'),
          ),
        ).thenAnswer((inv) async {
          final extra =
              inv.namedArguments[#extraContent] as Map<String, dynamic>?;
          correlationIds.add(extra?[MatrixEventField.correlationId] as String?);
          attachmentIds.add(extra?[MatrixEventField.attachmentId] as String?);
          return '\$event-${correlationIds.length}';
        });

        final attachments = [
          ChatAttachment(
            id: 'attachment-1',
            filename: 'a.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
          ChatAttachment(
            id: 'attachment-2',
            filename: 'b.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
        ];

        final message = await sdk.sendTextMessage(
          'Hi',
          attachments: attachments,
        );

        expect(correlationIds, hasLength(2));
        expect(correlationIds[0], isNotNull);
        expect(correlationIds[0], correlationIds[1]);
        expect(correlationIds[0], message.messageId);
        expect(attachmentIds, ['attachment-1', 'attachment-2']);
      },
    );

    test('returns error message and stops on send failure', () async {
      var sendCount = 0;
      when(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
          extraContent: any(named: 'extraContent'),
          notification: any(named: 'notification'),
        ),
      ).thenAnswer((_) async {
        sendCount++;
        if (sendCount == 1) {
          throw Exception('Network error');
        }
        return '\$event-$sendCount';
      });

      final attachments = [
        ChatAttachment(
          id: 'attachment-1',
          filename: 'a.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
          id: 'attachment-2',
          filename: 'b.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
      ];

      final result = await sdk.sendTextMessage(
        'Hello',
        attachments: attachments,
      );

      expect(result.status, ChatItemStatus.error);
      verify(() => repo.createMessage(any())).called(1);
    });

    test(
      'returns single logical message on full success with transportId',
      () async {
        var sendMediaCount = 0;
        when(
          () => core.sendMediaMessage(
            any(),
            any(),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
            caption: any(named: 'caption'),
            extraContent: any(named: 'extraContent'),
            notification: any(named: 'notification'),
          ),
        ).thenAnswer((_) async {
          sendMediaCount++;
          return '\$event-$sendMediaCount';
        });

        final attachments = [
          ChatAttachment(
            id: 'attachment-1',
            filename: 'first.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
          ChatAttachment(
            id: 'attachment-2',
            filename: 'second.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
        ];

        final result = await sdk.sendTextMessage(
          'Both',
          attachments: attachments,
        );

        expect(result.status, ChatItemStatus.sent);
        expect(result.isFromMe, isTrue);
        // The parent Message anchors on the first matrix event id (used as
        // the target for reactions/edits/redactions).
        expect(result.transportId, '\$event-1');
        expect(result.attachments, hasLength(2));
        expect(result.attachments[0].transportId, '\$event-1');
        expect(result.attachments[1].transportId, '\$event-2');
      },
    );

    test(
      'voice attachment sends voice metadata as Matrix audio info',
      () async {
        Map<String, dynamic>? sentExtraContent;
        String? sentContentType;
        when(
          () => core.sendMediaMessage(
            any(),
            any(),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
            caption: any(named: 'caption'),
            extraContent: any(named: 'extraContent'),
            notification: any(named: 'notification'),
          ),
        ).thenAnswer((inv) async {
          sentContentType = inv.namedArguments[#contentType] as String?;
          sentExtraContent =
              inv.namedArguments[#extraContent] as Map<String, dynamic>?;
          return '\$voice-event';
        });

        final result = await sdk.sendTextMessage(
          'voice note',
          attachments: [
            VoiceMessageMetadata.buildAttachment(
              base64: 'AAAA',
              durationMs: 1200,
              id: 'voice-attachment-1',
              filename: 'voice.m4a',
              waveform: [0, 40, 100],
            ),
          ],
        );

        expect(sentContentType, AttachmentMediaType.audioMp4.value);
        expect(
          sentExtraContent?[MatrixEventField.correlationId],
          result.messageId,
        );
        expect(
          sentExtraContent?[MatrixEventField.attachmentId],
          'voice-attachment-1',
        );
        expect(sentExtraContent?['info'], {
          'mimetype': AttachmentMediaType.audioMp4.value,
          'size': 3,
          'duration': 1200,
        });
        expect(
          sentExtraContent?[MatrixMediaAttachments.voiceContentKey],
          <String, dynamic>{},
        );
        expect(sentExtraContent?[MatrixMediaAttachments.audioContentKey], {
          'duration': 1200,
          'waveform': [0, 40, 100],
        });
        final voice = VoiceMessageMetadata.of(result.attachments.single);
        expect(VoiceMessageMetadata.isVoice(result.attachments.single), isTrue);
        expect(voice?.durationMs, 1200);
        expect(voice?.waveform, [0, 40, 100]);
      },
    );

    test('voice attachment defaults missing mediaType to audio/mp4', () async {
      String? sentContentType;
      when(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
          extraContent: any(named: 'extraContent'),
          notification: any(named: 'notification'),
        ),
      ).thenAnswer((inv) async {
        sentContentType = inv.namedArguments[#contentType] as String?;
        return '\$voice-event';
      });

      await sdk.sendTextMessage(
        '',
        attachments: [
          ChatAttachment(
            id: 'voice-attachment-1',
            data: ChatAttachmentData(base64: 'AAAA'),
            metadata: VoiceMessageMetadata(durationMs: 500).toMetadata(),
          ),
        ],
      );

      expect(sentContentType, VoiceMessageMetadata.defaultMediaType);
    });

    test('attachment without base64 data throws StateError', () async {
      final attachment = ChatAttachment(
        id: 'attachment-1',
        filename: 'empty.jpg',
        mediaType: 'image/jpeg',
      );

      expect(
        () => sdk.sendTextMessage('Hi', attachments: [attachment]),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'notification is passed only on the last sendMediaMessage call',
      () async {
        final notifications = <ChannelNotification?>[];
        when(
          () => core.sendMediaMessage(
            any(),
            any(),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
            caption: any(named: 'caption'),
            extraContent: any(named: 'extraContent'),
            notification: any(named: 'notification'),
          ),
        ).thenAnswer((inv) async {
          notifications.add(
            inv.namedArguments[#notification] as ChannelNotification?,
          );
          return '\$event-${notifications.length}';
        });

        final attachments = [
          ChatAttachment(
            id: 'attachment-1',
            filename: 'a.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
          ChatAttachment(
            id: 'attachment-2',
            filename: 'b.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
        ];

        await sdk.sendTextMessage('Hello', attachments: attachments);

        expect(notifications, hasLength(2));
        expect(notifications[0], isNull);
        expect(notifications[1], isNotNull);
      },
    );
  });

  group('MatrixChatSDK.downloadMedia', () {
    test('throws StateError when attachment has no transportId', () async {
      final attachment = ChatAttachment(
        id: 'attachment-1',
        filename: 'noref.bin',
        mediaType: 'application/octet-stream',
        format: 'test-format',
      );

      expect(() => sdk.downloadMedia(attachment), throwsA(isA<StateError>()));
    });

    test(
      'delegates to coreSDK.downloadMedia with MatrixEventMediaReference',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        when(
          () => core.downloadMedia(any(), any()),
        ).thenAnswer((_) async => bytes);

        final attachment = ChatAttachment(
          id: 'attachment-1',
          filename: 'one.bin',
          mediaType: 'application/octet-stream',
          format: 'test-format',
          transportId: '\$event-id',
        );

        final result = await sdk.downloadMedia(attachment);

        expect(result, bytes);
        final captured = verify(
          () => core.downloadMedia(captureAny(), captureAny()),
        ).captured;
        final reference = captured[1];
        expect(reference, isA<MatrixEventMediaReference>());
        expect((reference as MatrixEventMediaReference).eventId, '\$event-id');
      },
    );
  });
}
