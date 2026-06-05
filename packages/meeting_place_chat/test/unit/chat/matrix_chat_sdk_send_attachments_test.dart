import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/chat_typing_notification.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../_helpers/mocks.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

final _chatId = Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid);

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
        ),
      ).thenAnswer((_) async {
        sendMediaCount++;
        return '\$event-$sendMediaCount';
      });

      final attachments = [
        ChatAttachment(
          filename: 'a.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
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
        ),
      ).called(2);

      verify(() => repo.createMessage(any())).called(2);
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
        ),
      ).thenAnswer((inv) async {
        captions.add(inv.namedArguments[#caption] as String?);
        return '\$event-${captions.length}';
      });

      final attachments = [
        ChatAttachment(
          filename: 'a.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
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

    test('returns error message and stops on send failure', () async {
      var sendCount = 0;
      when(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
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
          filename: 'a.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
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

    test('returns first message on full success with transportId', () async {
      var sendMediaCount = 0;
      when(
        () => core.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          caption: any(named: 'caption'),
        ),
      ).thenAnswer((_) async {
        sendMediaCount++;
        return '\$event-$sendMediaCount';
      });

      final attachments = [
        ChatAttachment(
          filename: 'first.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        ),
        ChatAttachment(
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
      expect(result.transportId, '\$event-1');
    });

    test('attachment without base64 data throws ArgumentError', () async {
      final attachment = ChatAttachment(
        filename: 'empty.jpg',
        mediaType: 'image/jpeg',
      );

      expect(
        () => sdk.sendTextMessage('Hi', attachments: [attachment]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MatrixChatSDK.downloadMedia', () {
    test('throws StateError when message has no transportId', () async {
      final message = Message(
        chatId: _chatId,
        messageId: 'local-id',
        senderDid: _aliceDid,
        value: '',
        isFromMe: true,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.queued,
      );

      expect(
        () => sdk.downloadMedia(message),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'delegates to coreSDK.downloadMedia with MatrixEventMediaReference',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        when(
          () => core.downloadMedia(any(), any()),
        ).thenAnswer((_) async => bytes);

        final message = Message(
          chatId: _chatId,
          messageId: 'local-id',
          senderDid: _aliceDid,
          value: '',
          isFromMe: true,
          dateCreated: DateTime.now().toUtc(),
          status: ChatItemStatus.sent,
          transportId: '\$event-id',
        );

        final result = await sdk.downloadMedia(message);

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
