import 'package:collection/collection.dart';

enum ControlPlaneNotificationType {
  channelActivity('ChannelActivity'),
  invitationAccept('InvitationAccept'),
  invitationGroupAccept('InvitationGroupAccept'),
  groupMembershipFinalised('GroupMembershipFinalised'),
  offerFinalised('OfferFinalised'),
  invitationOutreach('InvitationOutreach');

  const ControlPlaneNotificationType(this.value);

  final String value;

  /// Looks up a [ControlPlaneNotificationType] by its wire [value].
  static ControlPlaneNotificationType? byValue(String value) {
    return ControlPlaneNotificationType.values.firstWhereOrNull(
      (t) => t.value == value,
    );
  }
}
