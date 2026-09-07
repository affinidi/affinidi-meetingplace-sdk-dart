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

  group('When using group lifecycle facade methods', () {
    group('and registering a group offer', () {
      test('it executes the matching command and returns its result', () async {
        final invitation = PlainTextMessage(
          id: 'invitation-id',
          from: 'did:key:admin',
          to: const ['did:key:member'],
          type: Uri.parse('https://example.com/group-invitation'),
          body: const {'goal': 'join-group'},
        );
        final validUntil = DateTime.utc(2030);
        final output = RegisterOfferGroupResult(
          groupId: 'group-id',
          groupDid: 'did:key:group',
          mediatorDid: 'did:web:mediator.example',
          offerLink: 'https://example.com/group-offers/1',
          mnemonic: 'group-chat',
          expiresAt: validUntil,
          maximumUsage: 10,
          oobInvitationMessage: invitation,
        );
        sdk.stubbedResult = output;

        final result = await sdk.registerOfferGroup(
          offerName: 'SDK group',
          offerDescription: 'Discuss SDK design',
          contactCard: contactCard,
          device: device,
          oobInvitationMessage: invitation,
          adminDid: 'did:key:admin',
          validUntil: validUntil,
          maximumUsage: 10,
          customMnemonic: 'group-chat',
          mediatorDid: 'did:web:custom-mediator.example',
          mediatorEndpoint: 'https://mediator.example',
          mediatorWSSEndpoint: 'wss://mediator.example',
          metadata: '{"topic":"sdk"}',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as RegisterOfferGroupCommand;
        expect(command.offerName, 'SDK group');
        expect(command.offerDescription, 'Discuss SDK design');
        expect(command.contactCard, same(contactCard));
        expect(command.device, same(device));
        expect(command.oobInvitationMessage, same(invitation));
        expect(command.adminDid, 'did:key:admin');
        expect(command.validUntil, same(validUntil));
        expect(command.maximumUsage, 10);
        expect(command.customMnemonic, 'group-chat');
        expect(command.mediatorDid, 'did:web:custom-mediator.example');
        expect(command.mediatorEndpoint, 'https://mediator.example');
        expect(command.mediatorWSSEndpoint, 'wss://mediator.example');
        expect(command.metadata, '{"topic":"sdk"}');
      });
    });

    group('and accepting a group offer', () {
      test('it executes the matching command and returns its result', () async {
        final output = AcceptOfferGroupResult(
          offerLink: 'https://example.com/group-offers/1',
          didcommMessage: 'message',
          validUntil: null,
          mediatorDid: 'did:web:mediator.example',
        );
        sdk.stubbedResult = output;

        final result = await sdk.acceptOfferGroup(
          mnemonic: 'group-chat',
          device: device,
          offerLink: 'https://example.com/group-offers/1',
          contactCard: contactCard,
          acceptOfferDid: 'did:key:accepting',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as AcceptOfferGroupCommand;
        expect(command.mnemonic, 'group-chat');
        expect(command.device, same(device));
        expect(command.offerLink, 'https://example.com/group-offers/1');
        expect(command.contactCard, same(contactCard));
        expect(command.acceptOfferDid, 'did:key:accepting');
      });
    });

    group('and adding a group member', () {
      test('it executes the matching command and returns its result', () async {
        final output = AddGroupMemberResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.addGroupMember(
          mnemonic: 'group-chat',
          groupId: 'group-id',
          memberDid: 'did:key:member',
          acceptOfferDid: 'did:key:accepting',
          offerLink: 'https://example.com/group-offers/1',
          contactCard: contactCard,
        );

        expect(result, same(output));
        final command = sdk.lastCommand as GroupAddMemberCommand;
        expect(command.mnemonic, 'group-chat');
        expect(command.groupId, 'group-id');
        expect(command.memberDid, 'did:key:member');
        expect(command.acceptOfferDid, 'did:key:accepting');
        expect(command.offerLink, 'https://example.com/group-offers/1');
        expect(command.contactCard, same(contactCard));
      });
    });

    group('and deregistering a group member', () {
      test('it executes the matching command and returns its result', () async {
        final output = DeregisterGroupMemberResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.deregisterGroupMember(
          groupId: 'group-id',
          memberId: 'did:key:member',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as GroupDeregisterMemberCommand;
        expect(command.groupId, 'group-id');
        expect(command.memberId, 'did:key:member');
      });
    });

    group('and deleting a group', () {
      test('it executes the matching command and returns its result', () async {
        final output = DeleteGroupResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.deleteGroup(groupId: 'group-id');

        expect(result, same(output));
        final command = sdk.lastCommand as GroupDeleteCommand;
        expect(command.groupId, 'group-id');
      });
    });

    group('and notifying a group channel', () {
      test('it executes the matching command and returns its result', () async {
        final output = NotifyGroupChannelResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.notifyGroupChannel(
          offerLink: 'https://example.com/group-offers/1',
          groupDid: 'did:key:group',
          type: 'member-added',
          memberDid: 'did:key:member',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as GroupNotifyChannelCommand;
        expect(command.offerLink, 'https://example.com/group-offers/1');
        expect(command.groupDid, 'did:key:group');
        expect(command.type, 'member-added');
        expect(command.memberDid, 'did:key:member');
      });
    });
  });
}
