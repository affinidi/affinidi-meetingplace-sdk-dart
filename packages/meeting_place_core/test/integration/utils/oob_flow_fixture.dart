import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../fixtures/contact_card_fixture.dart';
import '../../utils/sdk.dart';

class OobFlowFixture {
  OobFlowFixture._();

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

  static Future<OobFlowFixture> create() async {
    final fixture = OobFlowFixture._();

    fixture.aliceSDK = await initSDKInstance();
    fixture.bobSDK = await initSDKInstance();

    return fixture;
  }

  Future<dynamic> createOobFlow({String? did}) {
    return aliceSDK.createOobFlow(contactCard: aliceContactCard(), did: did);
  }

  Future<dynamic> acceptOobFlow(Uri oobUrl) {
    return bobSDK.acceptOobFlow(oobUrl, contactCard: bobContactCard());
  }

  static Future<Channel> waitForFirstChannelFromCreate(dynamic result) {
    final completer = Completer<Channel>();
    result.streamSubscription.listen((data) {
      if (!completer.isCompleted) {
        completer.complete(data.channel);
      }
    });

    return completer.future;
  }

  static Future<Channel> waitForFirstChannelFromAccept(dynamic result) {
    final completer = Completer<Channel>();
    result.streamSubscription.listen((data) {
      if (!completer.isCompleted) {
        completer.complete(data.channel);
      }
    });

    return completer.future;
  }
}
