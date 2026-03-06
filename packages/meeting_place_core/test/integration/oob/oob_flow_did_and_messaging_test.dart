import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/oob_flow_fixture.dart';

void main() {
  group('custom did', () {
    late OobFlowFixture fixture;

    setUp(() async {
      fixture = await OobFlowFixture.create();
    });

    test('uses given did as permanent channel did for OOB flow', () async {
      final did = await fixture.aliceSDK.generateDid();
      final didDoc = await did.getDidDocument();

      final createOobFlowResult = await fixture.createOobFlow(did: didDoc.id);
      await fixture.acceptOobFlow(createOobFlowResult.oobUrl);

      final aliceChannel = await OobFlowFixture.waitForFirstChannelFromCreate(
        createOobFlowResult,
      );

      expect(aliceChannel.permanentChannelDid, equals(didDoc.id));
    });

    test('generates OOB even if did is given', () async {
      final did = await fixture.aliceSDK.generateDid();
      final didDoc = await did.getDidDocument();

      final createOobFlowResult = await fixture.createOobFlow(did: didDoc.id);
      await fixture.acceptOobFlow(createOobFlowResult.oobUrl);

      final aliceChannel = await OobFlowFixture.waitForFirstChannelFromCreate(
        createOobFlowResult,
      );

      expect(aliceChannel.publishOfferDid, isNot(equals(didDoc.id)));
    });
  });

  test('Both parties can send messages', () async {
    final fixture = await OobFlowFixture.create();

    final did = await fixture.aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final createOobFlowResult = await fixture.createOobFlow(did: didDoc.id);
    final acceptOobFlowResult = await fixture.acceptOobFlow(
      createOobFlowResult.oobUrl,
    );

    final aliceCompleter = Completer<Channel>();
    createOobFlowResult.stream.listen((data) {
      aliceCompleter.complete(data.channel);
    });

    final bobCompleter = Completer<Channel>();
    acceptOobFlowResult.stream.listen((data) {
      bobCompleter.complete(data.channel);
    });

    final aliceChannel = await aliceCompleter.future;
    final bobChannel = await bobCompleter.future;

    await fixture.bobSDK.sendMessage(
      PlainTextMessage(
        id: 'test-message-id',
        type: Uri.parse('https://example.com/test'),
        from: bobChannel.permanentChannelDid,
        to: [bobChannel.otherPartyPermanentChannelDid!],
        body: {'hello': 'alice'},
      ),
      senderDid: bobChannel.permanentChannelDid!,
      recipientDid: bobChannel.otherPartyPermanentChannelDid!,
    );

    await fixture.aliceSDK.sendMessage(
      PlainTextMessage(
        id: 'test-message-id',
        type: Uri.parse('https://example.com/test'),
        from: aliceChannel.permanentChannelDid,
        to: [aliceChannel.otherPartyPermanentChannelDid!],
        body: {'hello': 'bob'},
      ),
      senderDid: aliceChannel.permanentChannelDid!,
      recipientDid: aliceChannel.otherPartyPermanentChannelDid!,
    );
  });
}
