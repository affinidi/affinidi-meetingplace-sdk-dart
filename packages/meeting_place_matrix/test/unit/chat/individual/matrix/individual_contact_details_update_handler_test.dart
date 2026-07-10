import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/individual/individual_contact_details_update_handler.dart';
import 'package:meeting_place_matrix/src/matrix_media_reference.dart';
import 'package:meeting_place_matrix/src/transport/matrix/outgoing/contact_details_update_sender.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../meeting_place_matrix.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _FakeChannel extends Fake implements Channel {}

class _MockChannel extends Mock implements Channel {}

class _MockLogger extends Mock implements MeetingPlaceChatSDKLogger {}

const _senderDid = 'did:test:bob';
const _otherPartyDid = 'did:test:bob';

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Uint8List _cardBytes(ContactCard card) =>
    Uint8List.fromList(utf8.encode(jsonEncode(card.toJson())));

MatrixRoomEvent _event(Map<String, dynamic> content) => MatrixRoomEvent(
  id: '\$test-event',
  roomId: 'test-room',
  type: 'com.affinidi.chat.contact-details-update',
  senderDid: _senderDid,
  content: content,
  timestamp: DateTime.utc(2026, 1, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(const MatrixEventMediaReference(''));
    registerFallbackValue(
      ContactCard(did: 'did:test:x', type: 'human', contactInfo: {}),
    );
  });

  group('IndividualContactDetailsUpdateHandler', () {
    late _MockCoreSDK coreSDK;
    late ChatStream chatStream;
    late _MockChannel channel;
    late _MockLogger logger;

    setUp(() {
      coreSDK = _MockCoreSDK();
      chatStream = ChatStream();
      channel = _MockChannel();
      logger = _MockLogger();

      when(() => channel.otherPartyContactCard = any()).thenAnswer((_) {
        return null;
      });
      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => channel);
      when(() => coreSDK.updateChannel(any())).thenAnswer((_) async {});
    });

    IndividualContactDetailsUpdateHandler buildHandler() =>
        IndividualContactDetailsUpdateHandler(
          coreSDK: coreSDK,
          chatStream: chatStream,
          otherPartyDid: _otherPartyDid,
          getChannel: () async => channel,
          logger: logger,
        );

    test('handles inline profileDetails', () async {
      final card = _card(_senderDid);
      final received = <StreamData>[];
      chatStream.listen(received.add);

      await buildHandler().handle(_event({'profileDetails': card.toJson()}));
      await Future<void>.delayed(Duration.zero);

      expect(received.length, 1);
      final event = received.first.event as ChatContactDetailsUpdateEvent;
      expect(event.contactCard.did, _senderDid);
    });

    test('handles contact_card_event_id by downloading media', () async {
      final card = _card(_senderDid);
      when(
        () => coreSDK.downloadMedia(any(), any()),
      ).thenAnswer((_) async => _cardBytes(card));

      final received = <StreamData>[];
      chatStream.listen(received.add);

      await buildHandler().handle(
        _event({ContactDetailsUpdateSender.contactCardEventIdKey: '\$evt-1'}),
      );
      await Future<void>.delayed(Duration.zero);

      final captured = verify(
        () => coreSDK.downloadMedia(any(), captureAny()),
      ).captured;
      expect((captured.single as MatrixEventMediaReference).eventId, '\$evt-1');

      expect(received.length, 1);
      final event = received.first.event as ChatContactDetailsUpdateEvent;
      expect(event.contactCard.did, _senderDid);
    });

    test('does nothing when content is empty', () async {
      final received = <StreamData>[];
      chatStream.listen(received.add);

      await buildHandler().handle(_event({}));
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      verifyNever(() => coreSDK.updateChannel(any()));
    });

    test('does nothing when media download fails', () async {
      when(
        () => coreSDK.downloadMedia(any(), any()),
      ).thenThrow(Exception('network error'));

      final received = <StreamData>[];
      chatStream.listen(received.add);

      await buildHandler().handle(
        _event({ContactDetailsUpdateSender.contactCardEventIdKey: '\$evt-bad'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      verifyNever(() => coreSDK.updateChannel(any()));
    });
  });
}
