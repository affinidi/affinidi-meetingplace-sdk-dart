import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  late RecordingMeetingPlaceControlPlaneSDK sdk;

  setUp(() {
    sdk = RecordingMeetingPlaceControlPlaneSDK();
  });

  group('When using direct connection invitation facade methods', () {
    group('and creating an invitation', () {
      test('it executes the matching command and returns its result', () async {
        final invitation = PlainTextMessage(
          id: 'invitation-id',
          from: 'did:key:alice',
          to: const ['did:key:bob'],
          type: Uri.parse('https://example.com/direct-connection'),
          body: const {'goal': 'connect'},
        );
        final output = CreateDirectConnectionInvitationResult(
          oobId: 'oob-id',
          oobUrl: 'https://example.com/invitations/oob-id',
          mediatorDid: 'did:web:mediator.example',
        );
        sdk.stubbedResult = output;

        final request = CreateOobRequest(
          oobInvitationMessage: invitation,
          mediatorDid: 'did:web:mediator.example',
        );
        final result = await sdk.createDirectConnectionInvitation(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as CreateOobRequest;
        expect(command.oobInvitationMessage, same(invitation));
        expect(command.mediatorDid, 'did:web:mediator.example');
      });
    });

    group('and retrieving an invitation', () {
      test('it executes the matching command and returns its result', () async {
        final output = GetDirectConnectionInvitationResult(
          invitationMessage: 'encoded-invitation',
          mediatorDid: 'did:web:mediator.example',
        );
        sdk.stubbedResult = output;

        final request = GetOobRequest(oobId: 'oob-id');
        final result = await sdk.getDirectConnectionInvitation(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as GetOobRequest;
        expect(command.oobId, 'oob-id');
      });
    });
  });
}
