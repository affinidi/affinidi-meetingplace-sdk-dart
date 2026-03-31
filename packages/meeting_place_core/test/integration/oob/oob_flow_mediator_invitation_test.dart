import 'dart:async';

import 'package:dio/dio.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../../fixtures/contact_card_fixture.dart';
import '../../utils/sdk.dart';

void main() {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  final aliceCard = ContactCardFixture.getContactCardFixture(
    did: 'did:test:alice',
    contactInfo: {
      'n': {'given': 'Alice'},
    },
  );

  final bobCard = ContactCardFixture.getContactCardFixture(
    did: 'did:test:bob',
    contactInfo: {
      'n': {'given': 'Bob', 'surname': 'A.'},
    },
  );

  test('creates oob invitation on mediator instance', () async {
    final did = await aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final oobUrl = await aliceSDK.mediator.createOob(did, getMediatorDid());

    final response = await Dio().get<Map<String, dynamic>>(oobUrl.toString());

    expect(response.data!['message'], equals('Success'));

    final actual = OobInvitationMessage.fromBase64(
      response.data!['data'] as String,
    );
    expect(actual.from, didDoc.id);
    expect(
      actual.toPlainTextMessage().type,
      Uri.parse('https://didcomm.org/out-of-band/2.0/invitation'),
    );

    final oobActual = await aliceSDK.mediator.getOob(oobUrl);
    expect(oobActual?.id, actual.id);
  });

  group('successfull channel creation for OOB flow', () {
    Channel? aliceChannel;
    Channel? bobChannel;

    setUpAll(() async {
      final aliceOnDoneCompleter = Completer<void>();
      final bobOnDoneCompleter = Completer<void>();

      final oobOfferSession = await aliceSDK.createOobFlow(
        contactCard: aliceCard,
      );

      oobOfferSession.stream.listen((data) {
        aliceChannel = data.channel;
        aliceOnDoneCompleter.complete();
      });

      final oobAcceptanceSession = await bobSDK.acceptOobFlow(
        oobOfferSession.oobUrl,
        contactCard: bobCard,
      );

      oobAcceptanceSession.stream.listen((data) {
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

    test('Contact cards match', () {
      expect(
        aliceChannel?.contactCard?.contactInfo,
        bobChannel?.otherPartyContactCard?.contactInfo,
      );

      expect(
        aliceChannel?.otherPartyContactCard?.contactInfo,
        bobChannel?.contactCard?.contactInfo,
      );
    });

    test('channel status is inaugurated', () {
      expect(aliceChannel?.status, equals(ChannelStatus.inaugurated));
      expect(bobChannel?.status, equals(ChannelStatus.inaugurated));
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

  test('creates oob with custom goal_code based on type', () async {
    final session = await aliceSDK.createOobFlow(
      contactCard: aliceCard,
      type: 'test',
    );

    expect(session.oobInvitationMessage.body.goalCode, equals('test'));
  });

  test('throws not found error if OOB invitation is not found', () async {
    final oob = await aliceSDK.createOobFlow(contactCard: aliceCard);
    final notFoundUri = Uri.parse('${oob.oobUrl}non-existing-path');

    expect(
      () async => await bobSDK.acceptOobFlow(notFoundUri, contactCard: bobCard),
      throwsA(
        isA<MeetingPlaceCoreSDKException>().having(
          (e) => e.code,
          'code',
          MeetingPlaceCoreSDKErrorCode.oobNotFound.value,
        ),
      ),
    );
  });

  test(
    'throws invalid type error if OOB invitation type doesn\'t match',
    () async {
      final oob = await aliceSDK.createOobFlow(
        contactCard: aliceCard,
        type: 'one',
      );

      expect(
        () async => await bobSDK.acceptOobFlow(
          oob.oobUrl,
          contactCard: bobCard,
          type: 'two',
        ),
        throwsA(
          isA<MeetingPlaceCoreSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCoreSDKErrorCode.oobInvalidType.value,
          ),
        ),
      );
    },
  );
}
