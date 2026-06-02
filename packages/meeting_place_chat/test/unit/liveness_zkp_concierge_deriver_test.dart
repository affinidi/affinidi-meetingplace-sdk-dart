import 'dart:convert';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:test/test.dart';

void main() {
  const chatId = 'chat-1';
  const contactName = 'Alice';
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 2);
  final t2 = DateTime.utc(2026, 1, 3);

  group('LivenessZkpConciergeDeriver', () {
    group('messageHasZkpAttachments', () {
      test('true for attachment-only ZKP messages', () {
        final message = _zkpMessage(
          messageId: 'm1',
          isFromMe: false,
          dateCreated: t0,
          attachments: [_zkpRequestAttachment()],
        );
        expect(
          LivenessZkpConciergeDeriver.messageHasZkpAttachments(message),
          isTrue,
        );
      });

      test('false when body text is non-empty', () {
        final message = Message(
          chatId: chatId,
          messageId: 'm1',
          senderDid: 'did:peer',
          isFromMe: false,
          dateCreated: t0,
          status: ChatItemStatus.confirmed,
          value: 'hello',
          attachments: [_zkpRequestAttachment()],
        );
        expect(
          LivenessZkpConciergeDeriver.messageHasZkpAttachments(message),
          isFalse,
        );
      });
    });

    group('deriveNoticesFromMessage', () {
      test('emits request notice for incoming request attachment', () {
        final notices = LivenessZkpConciergeDeriver.deriveNoticesFromMessage(
          _zkpMessage(
            messageId: 'req-1',
            isFromMe: false,
            dateCreated: t0,
            attachments: [_zkpRequestAttachment()],
          ),
          contactName: contactName,
        );

        expect(notices, hasLength(1));
        expect(
          notices.single.conciergeType,
          LivenessZkpConciergeTypes.humanZkpRequest,
        );
        expect(
          notices.single.messageId,
          LivenessZkpConciergeIds.requestReceived('req-1'),
        );
      });

      test('emits proof-shared notice for outgoing proof attachment', () {
        final notices = LivenessZkpConciergeDeriver.deriveNoticesFromMessage(
          _zkpMessage(
            messageId: 'proof-1',
            isFromMe: true,
            dateCreated: t0,
            attachments: [_zkpProofAttachment()],
          ),
          contactName: contactName,
        );

        expect(notices, hasLength(1));
        expect(
          notices.single.conciergeType,
          LivenessZkpConciergeTypes.humanZkpProofShared,
        );
      });
    });

    group('appendDerivedHumanZkpConciergeMessages', () {
      test(
        'derives unfulfilled request notice from latest incoming request',
        () {
          final request = _zkpMessage(
            messageId: 'req-1',
            isFromMe: false,
            dateCreated: t1,
            attachments: [_zkpRequestAttachment()],
          );

          final result =
              LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages(
                [request],
                contactName: contactName,
              );

          expect(
            _conciergeCount(result, LivenessZkpConciergeTypes.humanZkpRequest),
            1,
          );
          expect(
            _findConcierge(
              result,
              LivenessZkpConciergeTypes.humanZkpRequest,
            )!.messageId,
            LivenessZkpConciergeIds.requestReceived('req-1'),
          );
        },
      );

      test('uses latest incoming request when several exist', () {
        final older = _zkpMessage(
          messageId: 'req-old',
          isFromMe: false,
          dateCreated: t0,
          attachments: [_zkpRequestAttachment()],
        );
        final latest = _zkpMessage(
          messageId: 'req-new',
          isFromMe: false,
          dateCreated: t2,
          attachments: [_zkpRequestAttachment()],
        );

        final result =
            LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages([
              older,
              latest,
            ], contactName: contactName);

        expect(
          _findConcierge(
            result,
            LivenessZkpConciergeTypes.humanZkpRequest,
          )!.messageId,
          LivenessZkpConciergeIds.requestReceived('req-new'),
        );
      });

      test('omits request when my proof is on or after the latest request', () {
        final request = _zkpMessage(
          messageId: 'req-1',
          isFromMe: false,
          dateCreated: t1,
          attachments: [_zkpRequestAttachment()],
        );
        final proof = _zkpMessage(
          messageId: 'proof-1',
          isFromMe: true,
          dateCreated: t2,
          attachments: [_zkpProofAttachment()],
        );

        final result =
            LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages([
              request,
              proof,
            ], contactName: contactName);

        expect(
          _conciergeCount(result, LivenessZkpConciergeTypes.humanZkpRequest),
          0,
        );
        expect(
          _findConcierge(
            result,
            LivenessZkpConciergeTypes.humanZkpProofShared,
          )!.messageId,
          LivenessZkpConciergeIds.proofShared('proof-1'),
        );
      });

      test('keeps paused notice only for the latest request', () {
        final olderRequest = _zkpMessage(
          messageId: 'req-old',
          isFromMe: false,
          dateCreated: t0,
          attachments: [_zkpRequestAttachment()],
        );
        final latestRequest = _zkpMessage(
          messageId: 'req-new',
          isFromMe: false,
          dateCreated: t2,
          attachments: [_zkpRequestAttachment()],
        );
        final stalePaused = _conciergeFrom(
          LivenessZkpConciergeMessages.humanZkpPaused(
            chatId: chatId,
            dateCreated: t1,
            pausedForRequestNoticeMessageId:
                LivenessZkpConciergeIds.requestReceived('req-old'),
          ),
        );
        final currentPaused = _conciergeFrom(
          LivenessZkpConciergeMessages.humanZkpPaused(
            chatId: chatId,
            dateCreated: t2,
            pausedForRequestNoticeMessageId:
                LivenessZkpConciergeIds.requestReceived('req-new'),
          ),
        );

        final result =
            LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages([
              olderRequest,
              latestRequest,
              stalePaused,
              currentPaused,
            ], contactName: contactName);

        expect(
          result.where((i) => i.messageId == stalePaused.messageId),
          isEmpty,
        );
        expect(
          result.where((i) => i.messageId == currentPaused.messageId),
          hasLength(1),
        );
      });

      test('keeps proof-received notice for latest incoming proof', () {
        final theirProof = _zkpMessage(
          messageId: 'peer-proof',
          isFromMe: false,
          dateCreated: t1,
          attachments: [_zkpProofAttachment()],
        );
        final proofReceived = _conciergeFrom(
          LivenessZkpConciergeMessages.humanZkpProofReceived(
            chatId: chatId,
            messageId: LivenessZkpConciergeIds.proofReceived('peer-proof'),
            dateCreated: t1,
            contactName: contactName,
          ),
        );

        final result =
            LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages([
              theirProof,
              proofReceived,
            ], contactName: contactName);

        expect(
          result.where((i) => i.messageId == proofReceived.messageId),
          hasLength(1),
        );
      });

      test('derives proof-received notice from latest incoming proof', () {
        final olderProof = _zkpMessage(
          messageId: 'peer-proof-old',
          isFromMe: false,
          dateCreated: t0,
          attachments: [_zkpProofAttachment()],
        );
        final latestProof = _zkpMessage(
          messageId: 'peer-proof-new',
          isFromMe: false,
          dateCreated: t2,
          attachments: [_zkpProofAttachment()],
        );

        final result =
            LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages([
              olderProof,
              latestProof,
            ], contactName: contactName);

        final notice = _findConcierge(
          result,
          LivenessZkpConciergeTypes.humanZkpProofReceived,
        );
        expect(notice, isNotNull);
        expect(
          notice!.messageId,
          LivenessZkpConciergeIds.proofReceived('peer-proof-new'),
        );
      });

      test('leaves non-ZKP chat items unchanged', () {
        final text = Message(
          chatId: chatId,
          messageId: 'text-1',
          senderDid: 'did:peer',
          isFromMe: false,
          dateCreated: t0,
          status: ChatItemStatus.confirmed,
          value: 'hi',
        );

        final result =
            LivenessZkpConciergeDeriver.appendDerivedHumanZkpConciergeMessages([
              text,
            ], contactName: contactName);

        expect(result, [text]);
      });
    });
  });
}

Message _zkpMessage({
  required String messageId,
  required bool isFromMe,
  required DateTime dateCreated,
  required List<Attachment> attachments,
}) {
  return Message(
    chatId: 'chat-1',
    messageId: messageId,
    senderDid: isFromMe ? 'did:me' : 'did:peer',
    isFromMe: isFromMe,
    dateCreated: dateCreated,
    status: ChatItemStatus.confirmed,
    value: '',
    attachments: attachments,
  );
}

Attachment _zkpRequestAttachment() => Attachment(
  id: 'att-req',
  mediaType: 'application/json',
  format: LivenessZkpProtocol.livenessCheckRequestFormat,
  lastModifiedTime: DateTime.utc(2026),
  data: AttachmentData(
    json: jsonEncode({
      LivenessZkpProtocol.typeJsonKey:
          LivenessZkpProtocol.livenessRequestPayloadType,
      LivenessZkpProtocol.challengeNonceJsonKey:
          '0123456789abcdef0123456789abcdef'
          '0123456789abcdef0123456789abcdef',
    }),
  ),
);

Attachment _zkpProofAttachment() {
  const payload = LivenessProofPayload(proof: 'p', publicSignals: 's');
  return Attachment(
    id: 'att-proof',
    mediaType: 'application/json',
    format: LivenessZkpProtocol.livenessProofFormat,
    lastModifiedTime: DateTime.utc(2026),
    data: AttachmentData(json: jsonEncode(payload.toJson())),
  );
}

ConciergeMessage _conciergeFrom(LivenessZkpConciergeNotice notice) =>
    LivenessZkpConciergeChatMapper.toConciergeMessage(notice);

ConciergeMessage? _findConcierge(List<ChatItem> items, String type) {
  for (final item in items) {
    if (item is ConciergeMessage && item.conciergeType.value == type) {
      return item;
    }
  }
  return null;
}

int _conciergeCount(List<ChatItem> items, String type) => items
    .whereType<ConciergeMessage>()
    .where((m) => m.conciergeType.value == type)
    .length;
