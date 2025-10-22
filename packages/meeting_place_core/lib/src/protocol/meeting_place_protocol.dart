import 'package:collection/collection.dart';

enum MeetingPlaceProtocol {
  channelInauguration('https://affinidi.io/mpx/core-sdk/channel-inauguration'),

  connectionAccepted('https://affinidi.io/mpx/core-sdk/connection-accepted'),
  connectionSetup('https://affinidi.io/mpx/core-sdk/connection-setup'),
  connectionSetupGroup(
    'https://affinidi.io/mpx/core-sdk/connection-setup-group',
  ),

  groupDeleted('https://affinidi.io/mpx/core-sdk/group-delete'),
  groupMessage('https://affinidi.io/mpx/core-sdk/group-message'),

  groupMemberInauguration(
    'https://affinidi.io/mpx/core-sdk/group-member-inauguration',
  ),

  groupMemberDeregistered(
    'https://affinidi.io/mpx/core-sdk/group-member-deregistered',
  ),

  outreachInvitation('https://affinidi.io/mpx/core-sdk/outreach-invitation');

  const MeetingPlaceProtocol(this.value);

  final String value;

  static MeetingPlaceProtocol? byValue(String value) {
    return MeetingPlaceProtocol.values
        .firstWhereOrNull((e) => e.value == value);
  }
}
