import 'package:collection/collection.dart';

/// The DIDComm protocols used to drive the Meeting Place connection and
/// group lifecycle.
enum MeetingPlaceProtocol {
  /// Establishes a new channel between two parties.
  channelInauguration(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/channel-inauguration',
  ),

  /// Approves a connection request raised against a published offer.
  connectionRequestApproval(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/connection-request-approval',
  ),

  /// Accepts an invitation to connect.
  invitationAcceptance(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/invitation-acceptance',
  ),

  /// Accepts an invitation to join a group.
  invitationAcceptanceGroup(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/invitation-acceptance-group',
  ),

  /// Inaugurates a new member into a group.
  groupMemberInauguration(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/group-member-inauguration',
  ),

  /// Sends an outreach invitation to a prospective contact.
  outreachInvitation(
    'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/outreach-invitation',
  );

  const MeetingPlaceProtocol(this.value);

  /// The DIDComm protocol URI identifying this protocol.
  final String value;

  /// Returns the [MeetingPlaceProtocol] whose [value] matches [value], or
  /// `null` if none match.
  static MeetingPlaceProtocol? byValue(String value) {
    return MeetingPlaceProtocol.values.firstWhereOrNull(
      (e) => e.value == value,
    );
  }
}
