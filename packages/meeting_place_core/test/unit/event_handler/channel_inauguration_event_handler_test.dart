import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/event_handler/channel_inauguration_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/loggers/default_meeting_place_core_sdk_logger.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/protocol/message/channel_inauguration/channel_inauguration.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChannel());
  });

  const otherPartyDid = 'did:key:other-party';
  const myChannelDid = 'did:key:my-channel';
  const mediatorDid = 'did:web:mediator';

  final channel = Channel(
    offerLink: 'offer-link',
    publishOfferDid: myChannelDid,
    mediatorDid: mediatorDid,
    status: ChannelStatus.approved,
    isConnectionInitiator: false,
    contactCard: ContactCard(
      did: otherPartyDid,
      type: 'individual',
      contactInfo: const {'fullName': 'Alice'},
    ),
    type: ChannelType.individual,
  );

  final event = ChannelActivity(
    id: const Uuid().v4(),
    did: myChannelDid,
    type: 'channel-inauguration',
  );

  PlainTextMessage buildMessage({List<Attachment>? attachments}) {
    return ChannelInauguration.create(
      from: otherPartyDid,
      to: [myChannelDid],
      notificationToken: 'test-token',
      did: otherPartyDid,
      attachments: attachments,
    ).toPlainTextMessage();
  }

  ChannelInaugurationEventHandler buildHandler({
    void Function(Channel, List<Attachment>)? onAttachmentsReceived,
  }) {
    final channelService = MockChannelService();
    when(
      () => channelService.markChannelInauguratedForConnectionInitiator(
        any(),
        otherPartyNotificationToken: any(named: 'otherPartyNotificationToken'),
      ),
    ).thenAnswer((_) async {});

    return ChannelInaugurationEventHandler(
      wallet: MockWallet(),
      connectionOfferRepository: MockConnectionOfferRepository(),
      channelService: channelService,
      connectionManager: MockConnectionManager(),
      mediatorService: MockMediatorService(),
      logger: DefaultMeetingPlaceCoreSDKLogger(),
      options: ControlPlaneEventHandlerManagerOptions(
        onAttachmentsReceived: onAttachmentsReceived,
      ),
    );
  }

  group('ChannelInaugurationEventHandler', () {
    group('channelAttachments stream', () {
      test(
        'emits (channel, attachments) when message contains attachments',
        () async {
          final received = <(Channel, List<Attachment>)>[];
          final attachment = Attachment(
            id: const Uuid().v4(),
            data: AttachmentData(base64: 'dGVzdA=='),
          );

          final handler = buildHandler(
            onAttachmentsReceived: (ch, atts) => received.add((ch, atts)),
          );

          await handler.processMessage(
            buildMessage(attachments: [attachment]),
            event: event,
            channel: channel,
          );

          expect(received, hasLength(1));
          expect(received.first.$1.publishOfferDid, equals(myChannelDid));
          expect(received.first.$2, equals([attachment]));
        },
      );

      test('does not emit when message has no attachments', () async {
        final received = <(Channel, List<Attachment>)>[];
        final handler = buildHandler(
          onAttachmentsReceived: (ch, atts) => received.add((ch, atts)),
        );

        await handler.processMessage(
          buildMessage(),
          event: event,
          channel: channel,
        );

        expect(received, isEmpty);
      });
    });
  });
}

class _FakeChannel extends Fake implements Channel {}
