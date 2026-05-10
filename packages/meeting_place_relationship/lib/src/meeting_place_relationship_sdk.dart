import 'package:meeting_place_core/meeting_place_core.dart';

import 'models/vrc/relationship_credential.dart';
import 'parsers/vrc_parser.dart';

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

  /// Parses and verifies a raw VRC blob received over VDIP.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified VRC.
  ///
  /// - [vcBlob] — the raw serialised VC string from the VDIP response.
  /// - [channelId] — the channel through which the credential was received.
  Future<RelationshipCredential?> parseVrc({
    required String vcBlob,
    required String channelId,
  }) {
    return VrcParser.parse(vcBlob: vcBlob, channelId: channelId);
  }
}
