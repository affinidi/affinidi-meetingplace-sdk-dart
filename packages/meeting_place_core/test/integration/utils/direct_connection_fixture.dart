import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../fixtures/contact_card_fixture.dart';
import '../../utils/sdk.dart';

class DirectConnectionFixture {
  DirectConnectionFixture._();

  late final MeetingPlaceCoreSDK aliceSDK;
  late final MeetingPlaceCoreSDK bobSDK;

  static ContactCard aliceContactCard() {
    return ContactCardFixture.getContactCardFixture(
      did: 'did:test:alice',
      contactInfo: {
        'n': {'given': 'Alice'},
      },
    );
  }

  static ContactCard bobContactCard() {
    return ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );
  }

  static Future<DirectConnectionFixture> create({
    MeetingPlaceCoreSDKOptions? aliceOptions,
    MeetingPlaceCoreSDKOptions? bobOptions,
  }) async {
    final fixture = DirectConnectionFixture._();

    fixture.aliceSDK = await initSDKInstance(options: aliceOptions);
    fixture.bobSDK = await initSDKInstance(options: bobOptions);

    return fixture;
  }

  Future<DirectConnectionOfferSession> createDirectConnection({String? did}) {
    return aliceSDK.createDirectConnection(
      CreateDirectConnectionRequest(contactCard: aliceContactCard(), did: did),
    );
  }

  Future<DirectConnectionAcceptanceSession> acceptDirectConnection(
    Uri directConnectionUrl,
  ) {
    return bobSDK.acceptDirectConnection(
      AcceptDirectConnectionRequest(
        directConnectionUrl: directConnectionUrl,
        contactCard: bobContactCard(),
      ),
    );
  }

  static Future<Channel> waitForFirstChannelFromCreate(
    DirectConnectionOfferSession result,
  ) {
    final completer = Completer<Channel>();
    result.stream.listen((data) {
      if (!completer.isCompleted) {
        completer.complete(data.channel);
      }
    });

    return completer.future;
  }

  static Future<Channel> waitForFirstChannelFromAccept(
    DirectConnectionAcceptanceSession result,
  ) {
    final completer = Completer<Channel>();
    result.stream.listen((data) {
      if (!completer.isCompleted) {
        completer.complete(data.channel);
      }
    });

    return completer.future;
  }
}
