import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  late RecordingMeetingPlaceControlPlaneSDK sdk;
  late Device device;
  late ContactCard contactCard;

  setUp(() {
    sdk = RecordingMeetingPlaceControlPlaneSDK();
    device = Device(
      deviceToken: 'device-token',
      platformType: PlatformType.pushNotification,
    );
    contactCard = ContactCardImpl(
      did: 'did:key:alice',
      type: 'individual',
      contactInfo: const {'displayName': 'Alice'},
    );
  });

  group('When using offer lifecycle facade methods', () {
    group('and registering an offer', () {
      test('it executes the matching command and returns its output', () async {
        final invitation = PlainTextMessage(
          id: 'invitation-id',
          from: 'did:key:alice',
          to: const ['did:key:bob'],
          type: Uri.parse('https://example.com/invitation'),
          body: const {'goal': 'connect'},
        );
        final validUntil = DateTime.utc(2030);
        final output = RegisterOfferResult(
          mediatorDid: 'did:web:mediator.example',
          offerName: 'Coffee chat',
          offerLink: 'https://example.com/offers/1',
          mnemonic: 'coffee-chat',
          didcommMessage: invitation,
          expiresAt: validUntil,
          maximumUsage: 3,
          offerDescription: 'Discuss SDK design',
          score: 7,
        );
        sdk.stubbedResult = output;

        final request = RegisterOfferRequest(
          offerName: 'Coffee chat',
          offerDescription: 'Discuss SDK design',
          contactCard: contactCard,
          device: device,
          type: OfferType.invitation,
          oobInvitationMessage: invitation,
          transport: OfferTransport.didcomm,
          validUntil: validUntil,
          maximumUsage: 3,
          customMnemonic: 'coffee-chat',
          mediatorDid: 'did:web:custom-mediator.example',
          score: 7,
        );
        final result = await sdk.registerOffer(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as RegisterOfferRequest;
        expect(command.offerName, 'Coffee chat');
        expect(command.offerDescription, 'Discuss SDK design');
        expect(command.contactCard, same(contactCard));
        expect(command.device, same(device));
        expect(command.type, OfferType.invitation);
        expect(command.oobInvitationMessage, same(invitation));
        expect(command.transport, OfferTransport.didcomm);
        expect(command.validUntil, same(validUntil));
        expect(command.maximumUsage, 3);
        expect(command.customMnemonic, 'coffee-chat');
        expect(command.mediatorDid, 'did:web:custom-mediator.example');
        expect(command.score, 7);
      });
    });

    group('and deregistering an offer', () {
      test('it executes the matching command and returns its output', () async {
        final output = DeregisterOfferResult(success: true);
        sdk.stubbedResult = output;

        final request = DeregisterOfferRequest(
          offerLink: 'https://example.com/offers/1',
          mnemonic: 'coffee-chat',
        );
        final result = await sdk.deregisterOffer(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as DeregisterOfferRequest;
        expect(command.offerLink, 'https://example.com/offers/1');
        expect(command.mnemonic, 'coffee-chat');
      });
    });

    group('and finding an offer by mnemonic', () {
      test('it executes the matching command and returns its output', () async {
        final FindOfferByMnemonicResult output =
            NullFindOfferByMnemonicResult();
        sdk.stubbedResult = output;

        final request = QueryOfferRequest(mnemonic: 'coffee-chat');
        final result = await sdk.findOfferByMnemonic(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as QueryOfferRequest;
        expect(command.mnemonic, 'coffee-chat');
      });
    });

    group('and validating an offer mnemonic', () {
      test('it executes the matching command and returns its output', () async {
        final output = ValidateOfferMnemonicResult(isAvailable: true);
        sdk.stubbedResult = output;

        final request = ValidateOfferPhraseRequest(mnemonic: 'coffee-chat');
        final result = await sdk.validateOfferMnemonic(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as ValidateOfferPhraseRequest;
        expect(command.mnemonic, 'coffee-chat');
      });
    });

    group('and updating offer scores', () {
      test('it executes the matching command and returns its output', () async {
        final mnemonics = ['coffee-chat', 'tea-chat'];
        final output = UpdateOffersScoreResult(
          updatedOffers: mnemonics,
          failedOffers: const [],
        );
        sdk.stubbedResult = output;

        final request = UpdateOffersScoreRequest(
          score: 7,
          mnemonics: mnemonics,
        );
        final result = await sdk.updateOffersScore(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as UpdateOffersScoreRequest;
        expect(command.score, 7);
        expect(command.mnemonics, same(mnemonics));
      });
    });

    group('and accepting an offer', () {
      test('it executes the matching command and returns its output', () async {
        final output = AcceptOfferResult(
          offerLink: 'https://example.com/offers/1',
          offerName: 'Coffee chat',
          offerDescription: 'Discuss SDK design',
          didcommMessage: 'message',
          validUntil: null,
          maximumUsage: null,
          mediatorDid: 'did:web:mediator.example',
        );
        sdk.stubbedResult = output;

        final request = AcceptOfferRequest(
          mnemonic: 'coffee-chat',
          device: device,
          offerLink: 'https://example.com/offers/1',
          contactCard: contactCard,
          acceptOfferDid: 'did:key:accepting',
        );
        final result = await sdk.acceptOffer(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as AcceptOfferRequest;
        expect(command.mnemonic, 'coffee-chat');
        expect(command.device, same(device));
        expect(command.offerLink, 'https://example.com/offers/1');
        expect(command.contactCard, same(contactCard));
        expect(command.acceptOfferDid, 'did:key:accepting');
      });
    });

    group('and finalising an acceptance', () {
      test('it executes the matching command and returns its output', () async {
        final output = FinaliseAcceptanceResult(
          success: true,
          notificationToken: 'notification-token',
        );
        sdk.stubbedResult = output;

        final request = FinaliseAcceptanceRequest(
          mnemonic: 'coffee-chat',
          offerLink: 'https://example.com/offers/1',
          offerPublishedDid: 'did:key:publisher',
          otherPartyAcceptOfferDid: 'did:key:accepting',
          otherPartyPermanentChannelDid: 'did:key:channel',
          device: device,
          contactCard: contactCard,
        );
        final result = await sdk.finaliseAcceptance(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as FinaliseAcceptanceRequest;
        expect(command.mnemonic, 'coffee-chat');
        expect(command.offerLink, 'https://example.com/offers/1');
        expect(command.offerPublishedDid, 'did:key:publisher');
        expect(command.otherPartyAcceptOfferDid, 'did:key:accepting');
        expect(command.otherPartyPermanentChannelDid, 'did:key:channel');
        expect(command.device, same(device));
        expect(command.contactCard, same(contactCard));
      });
    });
  });
}
