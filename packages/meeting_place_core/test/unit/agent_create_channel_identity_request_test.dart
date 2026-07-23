import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/protocol/message/agent_create_channel_identity_request/agent_create_channel_identity_request.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

void main() {
  group('AgentCreateChannelIdentityRequest', () {
    const from = 'did:test:sender';
    const to = ['did:test:recipient'];
    const channelDid = 'did:test:channel';
    const offerLink = 'https://example.com/offer';
    const publishOfferDid = 'did:test:publish';

    late ContactCard contactCard;

    setUp(() {
      contactCard = ContactCardFixture.getContactCardFixture();
    });

    AgentCreateChannelIdentityRequest buildMsg() =>
        AgentCreateChannelIdentityRequest.create(
          from: from,
          to: to,
          channelDid: channelDid,
          offerLink: offerLink,
          publishOfferDid: publishOfferDid,
          contactCard: contactCard,
          transport: ChannelTransport.didcomm,
          contextKey: 'ctx-0',
        );

    group('.create', () {
      test('sets from, to and channelDid', () {
        final msg = buildMsg();

        expect(msg.from, equals(from));
        expect(msg.to, equals(to));
        expect(msg.body.channelDid, equals(channelDid));
      });

      test('sets offerLink, publishOfferDid and contactCard', () {
        final msg = buildMsg();

        expect(msg.body.offerLink, equals(offerLink));
        expect(msg.body.publishOfferDid, equals(publishOfferDid));
        expect(msg.body.contactCard, equals(contactCard));
        expect(msg.body.contextKey, equals('ctx-0'));
      });
    });

    group('toPlainTextMessage', () {
      test('sets correct type URI', () {
        expect(
          buildMsg().toPlainTextMessage().type.toString(),
          equals(
            'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/agent-create-channel-identity-request',
          ),
        );
      });

      test('serialises all fields into body', () {
        final body = buildMsg().toPlainTextMessage().body!;

        expect(body['channelDid'], equals(channelDid));
        expect(body['offerLink'], equals(offerLink));
        expect(body['publishOfferDid'], equals(publishOfferDid));
        expect(body['context_key'], equals('ctx-0'));
        expect(body['contactCard'], isA<Map<String, dynamic>>());
        expect(
          (body['contactCard'] as Map<String, dynamic>)['did'],
          equals(contactCard.did),
        );
      });
    });

    group('fromPlainTextMessage', () {
      test('round-trips all fields through toPlainTextMessage', () {
        final original = buildMsg();

        final restored = AgentCreateChannelIdentityRequest.fromPlainTextMessage(
          original.toPlainTextMessage(),
        );

        expect(restored.id, equals(original.id));
        expect(restored.from, equals(from));
        expect(restored.to, equals(to));
        expect(restored.body.channelDid, equals(channelDid));
        expect(restored.body.offerLink, equals(offerLink));
        expect(restored.body.publishOfferDid, equals(publishOfferDid));
        expect(restored.body.contactCard.did, equals(contactCard.did));
        expect(restored.body.contextKey, equals('ctx-0'));
      });
    });
  });
}
