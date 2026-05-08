import 'package:meeting_place_core/meeting_place_core.dart';

/// The Meeting Place Relationship SDK.
///
/// Provides typed, high-level access to R-Card and VRC exchange flows on
/// top of `MeetingPlaceCoreSDK`. Constructed once per session and
/// injected wherever relationship features are needed.
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  MeetingPlaceRelationshipSDK({required MeetingPlaceCoreSDK coreSDK})
    : _coreSDK = coreSDK;

  // TODO(earl): Wire up SDK calls — will be used by R-Card/VRC flow methods
  // added in upcoming PRs.
  // ignore: unused_field
  final MeetingPlaceCoreSDK _coreSDK;
}
