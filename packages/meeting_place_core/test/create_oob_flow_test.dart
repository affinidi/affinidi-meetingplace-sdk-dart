import 'dart:async';

import 'package:dio/dio.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'package:test/test.dart';

import 'fixtures/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUpAll(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  test('creates oob invitation on mediator instance', () async {
    final did = await aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final oobUrl = await aliceSDK.mediator.createOob(did, getMediatorDid());

    final response = await Dio().get(oobUrl.toString());

    expect(response.data!['message'], equals('Success'));

    final actual = OobInvitationMessage.fromBase64(response.data['data']);
    expect(actual.from, didDoc.id);
    expect(
      actual.type,
      Uri.parse('https://didcomm.org/out-of-band/2.0/invitation'),
    );

    final oobActual = await aliceSDK.mediator.getOob(oobUrl, didManager: did);
    expect(oobActual.id, actual.id);
  });

  // TEST CASES:
  // * channel gets closed at the end of the flow
  // * in the middle of flow
  // * when calling dispose -> mediator connection gets closed

  group('successfull channel creation for OOB flow', () {
    Channel? aliceChannel;
    Channel? bobChannel;

    setUpAll(() async {
      final aliceOnDoneCompleter = Completer();
      final bobOnDoneCompleter = Completer();

      final createOobFlowResult = await aliceSDK.createOobFlow(
        vCard: VCardFixture.alicePrimaryVCard,
      );

      createOobFlowResult.streamSubscription.listen((data) {
        aliceChannel = data.channel;
        aliceOnDoneCompleter.complete();
      });

      final acceptOobFlowResult = await bobSDK.acceptOobFlow(
        createOobFlowResult.oobUrl,
        vCard: VCardFixture.bobPrimaryVCard,
      );

      acceptOobFlowResult.streamSubscription.listen((data) {
        bobChannel = data.channel;
        bobOnDoneCompleter.complete();
      });

      await Future.wait([
        aliceOnDoneCompleter.future,
        bobOnDoneCompleter.future,
      ]);
    });

    test('permanent dids match', () {
      expect(
        aliceChannel?.permanentChannelDid,
        bobChannel?.otherPartyPermanentChannelDid,
      );

      expect(
        aliceChannel?.otherPartyPermanentChannelDid,
        bobChannel?.permanentChannelDid,
      );
    });

    test('vCards match', () {
      expect(aliceChannel?.vCard?.values, bobChannel?.otherPartyVCard?.values);

      expect(aliceChannel?.otherPartyVCard?.values, bobChannel?.vCard?.values);
    });

    test('channel status is inaugaurated', () {
      expect(aliceChannel?.status, equals(ChannelStatus.inaugaurated));
      expect(bobChannel?.status, equals(ChannelStatus.inaugaurated));
    });

    test('mediator dids match', () {
      expect(aliceChannel?.mediatorDid, equals(bobChannel?.mediatorDid));
    });

    test('other dids / ids match', () {
      expect(aliceChannel?.offerLink, bobChannel?.offerLink);

      expect(
        aliceChannel?.publishOfferDid,
        equals(bobChannel?.publishOfferDid),
      );

      expect(aliceChannel?.acceptOfferDid, equals(bobChannel?.acceptOfferDid));

      expect(
        aliceChannel?.outboundMessageId,
        equals(bobChannel?.outboundMessageId),
      );
    });

    test('type is oob', () {
      expect(aliceChannel?.type, ChannelType.oob);
    });
  });

  group('channel state before alice approves', () {
    Channel? bobChannel;

    setUpAll(() async {
      final createOobFlowResult = await aliceSDK.createOobFlow(
        vCard: VCardFixture.alicePrimaryVCard,
      );

      final acceptOobFlowResult = await bobSDK.acceptOobFlow(
        createOobFlowResult.oobUrl,
        vCard: VCardFixture.bobPrimaryVCard,
      );

      bobChannel = acceptOobFlowResult.channel;
    });

    test('status is waiting for approval', () {
      expect(bobChannel?.status, ChannelStatus.waitingForApproval);
    });

    test('initial values are set', () {
      expect(bobChannel?.offerLink, isNotNull);
      expect(bobChannel?.publishOfferDid, isNotNull);
      expect(bobChannel?.mediatorDid, isNotNull);
      expect(bobChannel?.outboundMessageId, isNotNull);
      expect(bobChannel?.acceptOfferDid, isNotNull);
      expect(bobChannel?.permanentChannelDid, isNotNull);
      expect(bobChannel?.type, equals(ChannelType.oob));
      expect(bobChannel?.otherPartyPermanentChannelDid, isNull);
      expect(bobChannel?.otherPartyVCard, isNull);

      expect(
        bobChannel?.vCard?.values,
        equals(VCardFixture.bobPrimaryVCard.values),
      );
    });
  });

  group('channel state after alice approves', () {
    Channel? bobChannel;
    Channel? channelBefore;

    setUpAll(() async {
      final createOobFlowResult = await aliceSDK.createOobFlow(
        vCard: VCardFixture.alicePrimaryVCard,
      );

      final acceptOobFlowResult = await bobSDK.acceptOobFlow(
        createOobFlowResult.oobUrl,
        vCard: VCardFixture.bobPrimaryVCard,
      );

      final bobCompleter = Completer<Channel>();
      acceptOobFlowResult.streamSubscription.listen((data) {
        bobCompleter.complete(data.channel);
      });

      channelBefore = acceptOobFlowResult.channel;
      bobChannel = await bobCompleter.future;
    });

    test('status is waiting for approval', () {
      expect(bobChannel?.status, ChannelStatus.inaugaurated);
    });

    test('initial values are still the same', () {
      expect(bobChannel?.offerLink, channelBefore?.offerLink);
      expect(bobChannel?.publishOfferDid, channelBefore?.publishOfferDid);
      expect(bobChannel?.mediatorDid, channelBefore?.mediatorDid);
      expect(bobChannel?.outboundMessageId, channelBefore?.outboundMessageId);
      expect(bobChannel?.acceptOfferDid, channelBefore?.acceptOfferDid);
      expect(
        bobChannel?.permanentChannelDid,
        channelBefore!.permanentChannelDid,
      );
      expect(bobChannel?.type, channelBefore!.type);
      expect(bobChannel?.vCard?.values, equals(channelBefore?.vCard?.values));
    });

    test('channel has been updated', () {
      expect(bobChannel?.otherPartyPermanentChannelDid, isNotNull);
      expect(
        bobChannel?.otherPartyVCard?.values,
        VCardFixture.alicePrimaryVCard.values,
      );
    });
  });

  test('uses separate stream for each createOobFlow call', () async {
    final resultA = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
    );

    final resultB = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
    );

    expect(
        resultA.streamSubscription, isNot(equals(resultB.streamSubscription)));
  });

  test('uses separate stream for each acceptOobFlow call', () async {
    final createOobFlowResult = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
    );

    final resultA = await bobSDK.acceptOobFlow(
      createOobFlowResult.oobUrl,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    final resultB = await bobSDK.acceptOobFlow(
      createOobFlowResult.oobUrl,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    expect(
        resultA.streamSubscription, isNot(equals(resultB.streamSubscription)));
  });

  test('uses given did as permanent channel did for OOB flow', () async {
    final did = await aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final createOobFlowResult = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
      did: didDoc.id,
    );

    await bobSDK.acceptOobFlow(
      createOobFlowResult.oobUrl,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    final aliceCompleter = Completer<Channel>();
    createOobFlowResult.streamSubscription.listen((data) {
      aliceCompleter.complete(data.channel);
    });

    expect(
      (await aliceCompleter.future).permanentChannelDid,
      equals(didDoc.id),
    );
  });

  test('generates OOB even if did is given', () async {
    final did = await aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final createOobFlowResult = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
      did: didDoc.id,
    );

    await bobSDK.acceptOobFlow(
      createOobFlowResult.oobUrl,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    final aliceCompleter = Completer<Channel>();
    createOobFlowResult.streamSubscription.listen((data) {
      aliceCompleter.complete(data.channel);
    });

    expect(
      (await aliceCompleter.future).publishOfferDid,
      isNot(equals(didDoc.id)),
    );
  });

  test('executes callback on timeout', () async {
    final createOobFlowResult = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
    );

    final aliceCompleter = Completer<String>();

    createOobFlowResult.streamSubscription.listen((data) => data);
    createOobFlowResult.streamSubscription.timeout(
      const Duration(milliseconds: 200),
      () => aliceCompleter.complete('timeout'),
    );

    expect(await aliceCompleter.future, equals('timeout'));
  });

  test('cancels timeout after receiving first event', () async {
    final createOobFlowResult = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
    );

    await bobSDK.acceptOobFlow(
      createOobFlowResult.oobUrl,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    createOobFlowResult.streamSubscription.listen((data) => data);
    createOobFlowResult.streamSubscription
        .timeout(const Duration(seconds: 1), () => fail('timeout executed'));

    await Future.delayed(const Duration(seconds: 2));
  }, skip: 'flaky test on CI');

  test('Both parties can send messages', () async {
    final did = await aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final createOobFlowResult = await aliceSDK.createOobFlow(
      vCard: VCardFixture.alicePrimaryVCard,
      did: didDoc.id,
    );

    final acceptOobFlowResult = await bobSDK.acceptOobFlow(
      createOobFlowResult.oobUrl,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    final aliceCompleter = Completer<Channel>();
    createOobFlowResult.streamSubscription.listen((data) {
      aliceCompleter.complete(data.channel);
    });

    final bobCompleter = Completer<Channel>();
    acceptOobFlowResult.streamSubscription.listen((data) {
      bobCompleter.complete(data.channel);
    });

    final aliceChannel = await aliceCompleter.future;
    final bobChannel = await bobCompleter.future;

    await bobSDK.sendMessage(
      PlainTextMessage(
          id: 'test-message-id',
          type: Uri.parse('https://example.com/test'),
          from: bobChannel.permanentChannelDid,
          to: [bobChannel.otherPartyPermanentChannelDid!],
          body: {'hello': 'alice'}),
      senderDid: bobChannel.permanentChannelDid!,
      recipientDid: bobChannel.otherPartyPermanentChannelDid!,
    );

    await aliceSDK.sendMessage(
      PlainTextMessage(
          id: 'test-message-id',
          type: Uri.parse('https://example.com/test'),
          from: aliceChannel.permanentChannelDid,
          to: [aliceChannel.otherPartyPermanentChannelDid!],
          body: {'hello': 'bob'}),
      senderDid: aliceChannel.permanentChannelDid!,
      recipientDid: aliceChannel.otherPartyPermanentChannelDid!,
    );
  });
}
