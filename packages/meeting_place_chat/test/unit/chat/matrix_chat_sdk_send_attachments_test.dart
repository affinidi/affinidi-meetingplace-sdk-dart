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
const _mxcUri1 = 'mxc://matrix.example.com/upload1';
const _mxcUri2 = 'mxc://matrix.example.com/upload2';

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

Attachment _uploadResult(String mxcUri, {String? filename}) => Attachment(
  id: 'upload-${mxcUri.hashCode}',
  filename: filename,
  mediaType: 'image/jpeg',
  format: AttachmentFormat.hostedMedia.value,
  byteCount: 100,
  data: AttachmentData(links: [Uri.parse(mxcUri)]),
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
  });

  setUp(() {
    core = MockCoreSDK();
    repo = _MockChatRepository();
    sdk = _buildSdk(core: core, repo: repo);

    when(
      () => core.getChannelByOtherPartyPermanentDid(any()),
    ).thenAnswer((_) async => _fakeChannel());

    when(() => core.updateChannel(any())).thenAnswer((_) async {});

    when(() => core.sendMessage(any())).thenAnswer((_) async => '\$event-id');

    when(() => repo.createMessage(any())).thenAnswer((inv) async {
      return inv.positionalArguments.first as ChatItem;
    });

    when(
      () => repo.getMessage(
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((inv) async {
      final messageId = inv.namedArguments[#messageId] as String;
      return Message(
        chatId: _chatId,
        messageId: messageId,
        senderDid: _aliceDid,
        value: '',
        isFromMe: true,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.sent,
      );
    });

    when(() => repo.updateMesssage(any())).thenAnswer((inv) async {
      return inv.positionalArguments.first as ChatItem;
    });
  });

  group('MatrixChatSDK.sendTextMessage multi-attachment', () {
    test('two attachments produce two separate room event sends', () async {
      var uploadCount = 0;
      when(
        () => core.uploadMedia(
          any(),
          senderDid: any(named: 'senderDid'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async {
        uploadCount++;
        return uploadCount == 1
            ? _uploadResult(_mxcUri1, filename: 'a.jpg')
            : _uploadResult(_mxcUri2, filename: 'b.jpg');
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

      // Two uploads + two room sends + one typing notification
      verify(
        () => core.uploadMedia(
          any(),
          senderDid: any(named: 'senderDid'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
        ),
      ).called(2);

      // Two createMessage calls (one per attachment)
      verify(() => repo.createMessage(any())).called(2);
    });

    test('caption is only on the first message body', () async {
      when(
        () => core.uploadMedia(
          any(),
          senderDid: any(named: 'senderDid'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async => _uploadResult(_mxcUri1));

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

      final captured = verify(() => core.sendMessage(captureAny())).captured;

      // Filter out the typing notification — keep only media room events
      final roomEvents = captured
          .whereType<MatrixOutgoingMessage>()
          .where((m) => m is! ChatTypingNotification)
          .toList();

      expect(roomEvents, hasLength(2));
      expect(roomEvents[0].content['body'], 'My caption');
      expect(roomEvents[1].content['body'], 'b.jpg');
    });

    test('returns error message and stops on send failure', () async {
      var sendCount = 0;
      when(
        () => core.uploadMedia(
          any(),
          senderDid: any(named: 'senderDid'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async => _uploadResult(_mxcUri1));

      when(() => core.sendMessage(any())).thenAnswer((_) async {
        sendCount++;
        if (sendCount == 1) {
          throw Exception('Network error');
        }
        return '\$event-id';
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

      // Only one createMessage because second was never attempted
      verify(() => repo.createMessage(any())).called(1);
    });

    test('returns first message on full success', () async {
      var uploadCount = 0;
      when(
        () => core.uploadMedia(
          any(),
          senderDid: any(named: 'senderDid'),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async {
        uploadCount++;
        return _uploadResult(
          'mxc://matrix.example.com/up$uploadCount',
          filename: 'file$uploadCount.jpg',
        );
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
    });
  });
}
