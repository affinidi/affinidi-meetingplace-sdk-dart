/// @docImport 'channel_activity.dart';
/// @docImport 'discovery_event.dart';
/// @docImport 'group_membership_finalised.dart';
/// @docImport 'invitation_accept.dart';
/// @docImport 'invitation_group_accept.dart';
/// @docImport 'invitation_outreach.dart';
/// @docImport 'offer_finalised.dart';
library;

/// The kind of notification event received from the control plane.
enum ControlPlaneEventType {
  /// The event type could not be determined.
  unknown,

  /// An [InvitationAccept] event.
  invitationAccept,

  /// An [InvitationGroupAccept] event.
  invitationGroupAccept,

  /// An [OfferFinalised] event.
  offerFinalised,

  /// A [GroupMembershipFinalised] event.
  groupMembershipFinalised,

  /// A [ChannelActivity] event.
  channelActivity,

  /// An [InvitationOutreach] event.
  invitationOutreach,
}

/// The processing status of a [ControlPlaneEvent].
enum ControlPlaneEventStatus {
  /// The status could not be determined.
  unknown,

  /// The event has not yet been processed.
  newEvent,

  /// The event has been deleted.
  deleted,

  /// The event has been processed.
  processed,
}
