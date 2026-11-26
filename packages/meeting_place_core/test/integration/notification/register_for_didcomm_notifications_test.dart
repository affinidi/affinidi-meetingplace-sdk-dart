@Tags(['integration'])
library;

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import '../../fixtures/contact_card_fixture.dart';
import '../../utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK sdk;

  setUpAll(() async {
    sdk = await initSDKInstance(withoutDevice: true);
  });

  test('register for DIDComm notifications returns new DIDManager', () async {
    final result = await sdk.registerForDIDCommNotifications(
      RegisterForDidcommNotificationsRequest(mediatorDid: getMediatorDid()),
    );

    // Run action to authenticate & register device
    await sdk.publishOffer(
      PublishOfferRequest(
        offerName: 'Sample Offer 123',
        offerDescription: 'Sample offer description',
        validUntil: DateTime.now().toUtc().add(const Duration(seconds: 30)),
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test:alice',
          contactInfo: {
            'n': {'given': 'Alice'},
          },
        ),
        type: SDKConnectionOfferType.invitation,
      ),
    );

    expect(sdk.controlPlaneSDK.device.deviceToken, result.device.deviceToken);
    expect(sdk.controlPlaneSDK.device.platformType, PlatformType.didcomm);
    expect(result.recipientDidManager, isA<DidManager>());
  });

  test('control plane delivers a DIDComm notification through the registered '
      'mediator', () async {
    // Alice gets notifications over DIDComm only; Bob is a regular client.
    final aliceSDK = await initSDKInstance(withoutDevice: true);
    final bobSDK = await initSDKInstance();

    final registration = await aliceSDK.registerForDIDCommNotifications(
      RegisterForDidcommNotificationsRequest(mediatorDid: getMediatorDid()),
    );
    final recipientDid =
        (await registration.recipientDidManager.getDidDocument()).id;

    final offer = await aliceSDK.publishOffer(
      PublishOfferRequest(
        offerName: 'DIDComm notification offer',
        offerDescription: 'Accepted to trigger a notification',
        maximumUsage: 1,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test:alice',
          contactInfo: {
            'n': {'given': 'Alice'},
          },
        ),
        type: SDKConnectionOfferType.invitation,
      ),
    );

    final found = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );
    await bobSDK.acceptOffer(
      AcceptOfferRequest(
        connectionOffer: found.connectionOffer!,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test:bob',
          contactInfo: {
            'n': {'given': 'Bob'},
          },
        ),
        senderInfo: 'Bob',
      ),
    );

    // The control plane authenticates to Alice's mediator as itself and
    // forwards the notification to her recipient DID. Read that DID's
    // queue on the mediator directly.
    final notification = await _waitForMessage(
      mediatorSDK: initMediatorSDK(),
      didManager: registration.recipientDidManager,
      type: MeetingPlaceNotificationProtocol.invitationAcceptance.value,
    );

    expect(notification.to, contains(recipientDid));
    expect(notification.from, isNotNull);
  });

  test('register for DIDComm notifications reuses given DID', () async {
    final recipientDid = await sdk.generateDid();
    final recipientDidDoc = await recipientDid.getDidDocument();

    final result = await sdk.registerForDIDCommNotifications(
      RegisterForDidcommNotificationsRequest(
        mediatorDid: 'did:web:other-mediator',
        recipientDid: recipientDidDoc.id,
      ),
    );

    final actual = await result.recipientDidManager.getDidDocument();
    expect(recipientDidDoc.id, equals(actual.id));
  });
}

/// Polls [didManager]'s queue on the test mediator until a message of [type]
/// arrives, deleting what it reads, or fails after [timeout].
Future<PlainTextMessage> _waitForMessage({
  required MeetingPlaceMediatorSDK mediatorSDK,
  required DidManager didManager,
  required String type,
  Duration timeout = const Duration(seconds: 30),
  Duration interval = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  final seen = <String>[];
  while (DateTime.now().isBefore(deadline)) {
    final results = await mediatorSDK.fetchMessages(
      FetchMessagesRequest(didManager: didManager, deleteOnRetrieve: true),
    );
    for (final result in results) {
      final message = result.message;
      if (message == null) continue;
      final messageType = message.type.toString();
      if (messageType == type) return message;
      seen.add(messageType);
    }
    await Future<void>.delayed(interval);
  }
  fail('No $type message within ${timeout.inSeconds}s; saw: $seen');
}
