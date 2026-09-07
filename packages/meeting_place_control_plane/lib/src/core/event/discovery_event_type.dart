// ignore_for_file: constant_identifier_names
// TODO: change enum to comply with linting rules

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
  Unknown,

  /// An [InvitationAccept] event.
  InvitationAccept,

  /// An [InvitationGroupAccept] event.
  InvitationGroupAccept,

  /// An [OfferFinalised] event.
  OfferFinalised,

  /// A [GroupMembershipFinalised] event.
  GroupMembershipFinalised,

  /// A [ChannelActivity] event.
  ChannelActivity,

  /// An [InvitationOutreach] event.
  InvitationOutreach,
}

/// The processing status of a [ControlPlaneEvent].
enum ControlPlaneEventStatus {
  /// The status could not be determined.
  Unknown,

  /// The event has not yet been processed.
  New,

  /// The event has been deleted.
  Deleted,

  /// The event has been processed.
  Processed,
}
