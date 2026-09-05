@Tags(['integration'])
library;

import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/direct_connection_fixture.dart';

void main() {
  group('custom did', () {
    late DirectConnectionFixture fixture;

    setUpAll(() async {
      fixture = await DirectConnectionFixture.create();
    });

    test(
      'uses given did as permanent channel did for direct connection',
      () async {
        final did = await fixture.aliceSDK.generateDid();
        final didDoc = await did.getDidDocument();

        final createDirectConnectionResult = await fixture
            .createDirectConnection(did: didDoc.id);
        await fixture.acceptDirectConnection(
          createDirectConnectionResult.directConnectionUrl,
        );

        final aliceChannel =
            await DirectConnectionFixture.waitForFirstChannelFromCreate(
              createDirectConnectionResult,
            );

        expect(aliceChannel.permanentChannelDid, equals(didDoc.id));
      },
    );

    test(
      'generates a direct connection invitation even if did is given',
      () async {
        final did = await fixture.aliceSDK.generateDid();
        final didDoc = await did.getDidDocument();

        final createDirectConnectionResult = await fixture
            .createDirectConnection(did: didDoc.id);
        await fixture.acceptDirectConnection(
          createDirectConnectionResult.directConnectionUrl,
        );

        final aliceChannel =
            await DirectConnectionFixture.waitForFirstChannelFromCreate(
              createDirectConnectionResult,
            );

        expect(aliceChannel.publishOfferDid, isNot(equals(didDoc.id)));
      },
    );
  });

  test('Both parties can send messages', () async {
    final fixture = await DirectConnectionFixture.create();

    final did = await fixture.aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final createDirectConnectionResult = await fixture.createDirectConnection(
      did: didDoc.id,
    );
    final acceptDirectConnectionResult = await fixture.acceptDirectConnection(
      createDirectConnectionResult.directConnectionUrl,
    );

    final aliceCompleter = Completer<Channel>();
    createDirectConnectionResult.stream.listen((data) {
      aliceCompleter.complete(data.channel);
    });

    final bobCompleter = Completer<Channel>();
    acceptDirectConnectionResult.stream.listen((data) {
      bobCompleter.complete(data.channel);
    });

    final aliceChannel = await aliceCompleter.future;
    final bobChannel = await bobCompleter.future;

    await fixture.bobSDK.sendMessage(
      DidCommOutgoingMessage(
        senderDid: bobChannel.permanentChannelDid!,
        recipientDid: bobChannel.otherPartyPermanentChannelDid!,
        payload: PlainTextMessage(
          id: 'test-message-id',
          type: Uri.parse('https://example.com/test'),
          from: bobChannel.permanentChannelDid,
          to: [bobChannel.otherPartyPermanentChannelDid!],
          body: {'hello': 'alice'},
        ),
      ),
    );

    await fixture.aliceSDK.sendMessage(
      DidCommOutgoingMessage(
        senderDid: aliceChannel.permanentChannelDid!,
        recipientDid: aliceChannel.otherPartyPermanentChannelDid!,
        payload: PlainTextMessage(
          id: 'test-message-id',
          type: Uri.parse('https://example.com/test'),
          from: aliceChannel.permanentChannelDid,
          to: [aliceChannel.otherPartyPermanentChannelDid!],
          body: {'hello': 'bob'},
        ),
      ),
    );
  });
}
