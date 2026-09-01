import 'package:collection/collection.dart';

enum MeetingPlaceProtocol {
  channelInauguration(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/channel-inauguration',
  ),

  connectionRequestApproval(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/connection-request-approval',
  ),

  invitationAcceptance(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/invitation-acceptance',
  ),

  invitationAcceptanceGroup(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/invitation-acceptance-group',
  ),

  groupMemberInauguration(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/group-member-inauguration',
  ),

  outreachInvitation(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/outreach-invitation',
  );

  const MeetingPlaceProtocol(this.value);

  final String value;

  static MeetingPlaceProtocol? byValue(String value) {
    return MeetingPlaceProtocol.values.firstWhereOrNull(
      (e) => e.value == value,
    );
  }
}
